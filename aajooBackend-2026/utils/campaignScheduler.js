const leadService = require('./leadService');
const model = require('../models');
const { sendBotPenguinTemplate } = require('./bookingNotificationService');

// Tables the scheduler depends on. If any are missing on the target DB (e.g.
// chatbot migrations haven't been run on prod yet), the scheduler will quietly
// disable itself instead of logging a "doesn't exist" error every tick.
const REQUIRED_TABLES = [
  'tbl_chatbot_campaigns',
  'tbl_chatbot_sessions',
  'tbl_chatbot_leads',
  'tbl_chatbot_logs',
];

let chatbotTablesPresent = null; // null = unknown, true/false = checked

const ensureChatbotTablesPresent = async () => {
  if (chatbotTablesPresent !== null) return chatbotTablesPresent;
  try {
    const qi = model.sequelize.getQueryInterface();
    const allTables = await qi.showAllTables();
    const lowered = allTables.map((t) => String(t).toLowerCase());
    const missing = REQUIRED_TABLES.filter(
      (t) => !lowered.includes(t.toLowerCase())
    );
    if (missing.length) {
      console.warn(
        `[Campaign] Chatbot tables missing on this DB: ${missing.join(', ')}. ` +
        `Scheduler will stay disabled until migrations are applied ` +
        `(see scripts/runChatbotMigrations.js).`
      );
      chatbotTablesPresent = false;
    } else {
      chatbotTablesPresent = true;
    }
  } catch (err) {
    // If the precheck itself fails (e.g. DB unreachable), don't crash —
    // assume tables are missing for this boot and stay quiet.
    console.warn('[Campaign] Could not verify chatbot tables; scheduler disabled this run:', err.message);
    chatbotTablesPresent = false;
  }
  return chatbotTablesPresent;
};

const DEFAULT_USER_NAME = 'Guest';
const DEFAULT_COUNTRY_CODE = process.env.BOTPENGUIN_DEFAULT_COUNTRY_CODE || '91';
const DEFAULT_24HR_OFFER_AMOUNT =
  process.env.BOTPENGUIN_24HR_OFFER_AMOUNT ||
  process.env.BOTPENGUIN_24HR_DISCOUNT_AMOUNT ||
  process.env.BOTPENGUIN_24HR_OFFER_VALUE ||
  500;

const normalizeWaId = (value) => {
  const digits = String(value || '').replace(/\D/g, '');
  if (!digits) return null;

  if (digits.length === 10) {
    return `${DEFAULT_COUNTRY_CODE}${digits}`;
  }

  return digits;
};

const getCampaignRecipient = async (campaign) => {
  if (!campaign?.campaign_session_id) {
    return {
      userName: DEFAULT_USER_NAME,
      waId: normalizeWaId(campaign?.campaign_phone),
    };
  }

  const [session, lead] = await Promise.all([
    model.tbl_chatbot_sessions.findOne({
      where: { cs_session_id: campaign.campaign_session_id },
      attributes: ['cs_user_name', 'cs_phone'],
      raw: true,
    }),
    model.tbl_chatbot_leads.findOne({
      where: { lead_session_id: campaign.campaign_session_id },
      attributes: ['lead_name', 'lead_phone'],
      raw: true,
    }),
  ]);

  return {
    userName: session?.cs_user_name || lead?.lead_name || DEFAULT_USER_NAME,
    waId: normalizeWaId(session?.cs_phone || lead?.lead_phone || campaign.campaign_phone),
  };
};

const buildBodyParams = (...values) => {
  const normalizedValues = values
    .map((value) => (value == null ? '' : String(value).trim()))
    .filter((value) => value.length > 0);

  if (!normalizedValues.length) return [];

  return [
    {
      type: 'body',
      parameters: normalizedValues.map((text) => ({
        type: 'text',
        text,
      })),
    },
  ];
};

const get24hrOfferAmount = (campaign) => {
  const rawAmount = campaign?.campaign_offer_amount || DEFAULT_24HR_OFFER_AMOUNT;
  if (rawAmount == null) return null;

  const amount = String(rawAmount).replace(/[^\d.]/g, '').trim();
  return amount || null;
};

const getTemplateConfig = (campaignType, campaign) => {
  const assignTo = process.env.BOTPENGUIN_TEMPLATE_ASSIGN_TO || undefined;
  const city = campaign?.campaign_city || null;
  const hasCity = Boolean(city);
  const offerAmount = get24hrOfferAmount(campaign);
  const safeOfferAmount = offerAmount || '0';

  if (campaignType === '2hr_reminder') {
    return {
      templateId: hasCity
        ? process.env.BOTPENGUIN_2HR_TEMPLATE_ID
        : process.env.BOTPENGUIN_2HR_NO_CITY_TEMPLATE_ID,
      params: buildBodyParams(city),
      tags: ['lead_capture', '2hr_reminder'],
      assignTo,
      city,
      offerAmount: null,
    };
  }

  // 24hr offer
  return {
    templateId: hasCity
      ? process.env.BOTPENGUIN_24HR_TEMPLATE_ID
      : process.env.BOTPENGUIN_24HR_NO_CITY_TEMPLATE_ID,
    params: hasCity
      ? buildBodyParams(safeOfferAmount, city)
      : buildBodyParams(safeOfferAmount),
    tags: ['lead_capture', '24hr_offer'],
    assignTo,
    city,
    offerAmount: safeOfferAmount,
  };
};

// ─── RUNNER FUNCTIONS ──────────────────────────────────────────────────────────

const run2hrCampaign = async () => {
  const campaigns = await leadService.getCampaignsDueFor2hrReminder();
  console.log(`[Campaign] 2hr runner: ${campaigns.length} campaigns due`);

  for (const campaign of campaigns) {
    try {
      const recipient = await getCampaignRecipient(campaign);
      const templateConfig = getTemplateConfig('2hr_reminder', campaign);

      const result = await sendBotPenguinTemplate({
        userName: recipient.userName,
        waId: recipient.waId,
        templateId: templateConfig.templateId,
        params: templateConfig.params,
        tags: templateConfig.tags,
        assignTo: templateConfig.assignTo,
        actionType: 'CampaignScheduler_2hrReminder',
      });

      if (result.sent) {
        await leadService.mark2hrSent(campaign.id);
      } else {
        console.error(`[Campaign] 2hr send failed for ${campaign.campaign_phone}:`, result);
      }

      await leadService.logEvent({
        sessionId: campaign.campaign_session_id,
        phone: campaign.campaign_phone,
        type: 'campaign_sent',
        data: {
          type: '2hr_reminder',
          city: campaign.campaign_city,
          offer_amount: templateConfig.offerAmount,
          sent: result.sent,
          channel: campaign.campaign_channel,
          wa_id: recipient.waId,
          user_name: recipient.userName,
          template_id: templateConfig.templateId || null,
          response_status: result.status || null,
          response_message: result.reason || null,
          response: result.response || null,
        },
        channel: campaign.campaign_channel,
      });

      console.log(`[Campaign] 2hr sent to ${campaign.campaign_phone} | sent: ${result.sent}`);
    } catch (err) {
      console.error(`[Campaign] 2hr error for ${campaign.campaign_phone}:`, err.message);
    }
  }
};

const run24hrCampaign = async () => {
  const campaigns = await leadService.getCampaignsDueFor24hrOffer();
  console.log(`[Campaign] 24hr runner: ${campaigns.length} campaigns due`);

  for (const campaign of campaigns) {
    try {
      const recipient = await getCampaignRecipient(campaign);
      const templateConfig = getTemplateConfig('24hr_offer', campaign);

      const result = await sendBotPenguinTemplate({
        userName: recipient.userName,
        waId: recipient.waId,
        templateId: templateConfig.templateId,
        params: templateConfig.params,
        tags: templateConfig.tags,
        assignTo: templateConfig.assignTo,
        actionType: 'CampaignScheduler_24hrOffer',
      });

      if (result.sent) {
        await leadService.mark24hrSent(campaign.id);
      } else {
        console.error(`[Campaign] 24hr send failed for ${campaign.campaign_phone}:`, result);
      }

      await leadService.logEvent({
        sessionId: campaign.campaign_session_id,
        phone: campaign.campaign_phone,
        type: 'campaign_sent',
        data: {
          type: '24hr_offer',
          city: campaign.campaign_city,
          offer_amount: templateConfig.offerAmount,
          sent: result.sent,
          channel: campaign.campaign_channel,
          wa_id: recipient.waId,
          user_name: recipient.userName,
          template_id: templateConfig.templateId || null,
          response_status: result.status || null,
          response_message: result.reason || null,
          response: result.response || null,
        },
        channel: campaign.campaign_channel,
      });

      if (result.sent) {
        // After 24hr offer, stop the campaign automatically
        await leadService.stopCampaign({
          sessionId: campaign.campaign_session_id,
          reason: 'campaign_completed',
        });
      }

      console.log(`[Campaign] 24hr offer sent to ${campaign.campaign_phone} | sent: ${result.sent}`);
    } catch (err) {
      console.error(`[Campaign] 24hr error for ${campaign.campaign_phone}:`, err.message);
    }
  }
};

// ─── SCHEDULER SETUP ──────────────────────────────────────────────────────────

let schedulerInterval = null;

// Change this line for production:
const INTERVAL_MS = process.env.NODE_ENV === 'production'
  ? 15 * 60 * 1000   // 15 minutes in production
  : 2 * 60 * 1000;   // 2 minutes for testing

const runAllCampaigns = async () => {
  // Skip silently when chatbot tables are missing — prevents the recurring
  // "tbl_chatbot_campaigns doesn't exist" spam in prod logs.
  const ok = await ensureChatbotTablesPresent();
  if (!ok) {
    stopScheduler();
    return;
  }
  console.log('[Campaign] Running campaign scheduler tick...');
  try {
    await run2hrCampaign();
    await run24hrCampaign();
  } catch (err) {
    console.error('[Campaign] Scheduler tick error:', err.message);
  }
};

const startScheduler = async () => {
  if (schedulerInterval) {
    console.log('[Campaign] Scheduler already running.');
    return;
  }

  // Preflight before scheduling any ticks so we don't even register the
  // interval on a DB that doesn't have chatbot tables yet.
  const ok = await ensureChatbotTablesPresent();
  if (!ok) {
    console.warn('[Campaign] Scheduler not started — chatbot tables missing.');
    return;
  }

  console.log(`[Campaign] Starting drip campaign scheduler (every ${INTERVAL_MS / 60000} minutes)...`);

  // Run immediately on start
  runAllCampaigns();

  // Then on the configured interval
  schedulerInterval = setInterval(runAllCampaigns, INTERVAL_MS);
};

const stopScheduler = () => {
  if (schedulerInterval) {
    clearInterval(schedulerInterval);
    schedulerInterval = null;
    console.log('[Campaign] Scheduler stopped.');
  }
};

module.exports = {
  startScheduler,
  stopScheduler,
  runAllCampaigns
};
