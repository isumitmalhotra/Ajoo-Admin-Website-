const model = require('../models');

const captureLead = async ({ sessionId, name, phone, city, checkin, checkout, guests, channel = 'web' }) => {
  try {
    const existing = await model.tbl_chatbot_leads.findOne({
      where: { lead_session_id: sessionId },
    });

    if (existing) {
      await existing.update({
        lead_name: name || existing.lead_name,
        lead_city: city || existing.lead_city,
        lead_checkin: checkin || existing.lead_checkin,
        lead_checkout: checkout || existing.lead_checkout,
        lead_guests: guests || existing.lead_guests,
        lead_status: existing.lead_booked ? 'booked' : 'searching',
      });
      return existing;
    }

    const lead = await model.tbl_chatbot_leads.create({
      lead_session_id: sessionId,
      lead_name: name || null,
      lead_phone: phone,
      lead_city: city || null,
      lead_checkin: checkin || null,
      lead_checkout: checkout || null,
      lead_guests: guests ? Number(guests) : null,
      lead_interest: 'property_search',
      lead_status: 'new',
      lead_channel: channel,
      lead_booked: 0,
    });

    return lead;
  } catch (err) {
    console.error('[LeadService] captureLead error:', err.message);
    return null;
  }
};


const markLeadBooked = async ({ sessionId, phone }) => {
  try {
    const where = sessionId
      ? { lead_session_id: sessionId }
      : { lead_phone: phone };

    await model.tbl_chatbot_leads.update(
      {
        lead_booked: 1,
        lead_booked_at: new Date(),
        lead_status: 'booked',
      },
      { where }
    );

    // Also stop the campaign
    await stopCampaign({ sessionId, phone, reason: 'booking_created' });

    return { success: true };
  } catch (err) {
    console.error('[LeadService] markLeadBooked error:', err.message);
    return { success: false };
  }
};

const startCampaign = async ({ sessionId, phone, city, channel = 'web' }) => {
  try {
    const existing = await model.tbl_chatbot_campaigns.findOne({
      where: { campaign_session_id: sessionId },
    });

    if (existing) {
      if (existing.campaign_status === 'stopped') {
        // Restart if previously stopped and user is searching again
        await existing.update({
          campaign_status: 'active',
          campaign_city: city || existing.campaign_city,
          reminder_2hr_sent: 0,
          reminder_2hr_at: null,
          offer_24hr_sent: 0,
          offer_24hr_at: null,
          stopped_at: null,
          stop_reason: null,
        });
      }
      return existing;
    }

    const campaign = await model.tbl_chatbot_campaigns.create({
      campaign_session_id: sessionId,
      campaign_phone: phone,
      campaign_city: city || null,
      campaign_channel: channel,
      campaign_status: 'active',
      reminder_2hr_sent: 0,
      offer_24hr_sent: 0,
    });

    return campaign;
  } catch (err) {
    console.error('[LeadService] startCampaign error:', err.message);
    return null;
  }
};

const stopCampaign = async ({ sessionId, phone, reason = 'manual' }) => {
  try {
    const where = {};
    if (sessionId) where.campaign_session_id = sessionId;
    else if (phone) where.campaign_phone = phone;
    else return { success: false };

    await model.tbl_chatbot_campaigns.update(
      {
        campaign_status: 'stopped',
        stopped_at: new Date(),
        stop_reason: reason,
      },
      { where }
    );

    return { success: true };
  } catch (err) {
    console.error('[LeadService] stopCampaign error:', err.message);
    return { success: false };
  }
};

const getCampaignsDueFor2hrReminder = async () => {
  // Use env var so you can control from .env without code change
  const delayMs = process.env.NODE_ENV === 'production'
    ? 2 * 60 * 60 * 1000   // 2 hours production
    : 2 * 60 * 1000;        // 5 minutes testing

  const cutoff = new Date(Date.now() - delayMs);

  return model.tbl_chatbot_campaigns.findAll({
    where: {
      campaign_status: 'active',
      reminder_2hr_sent: 0,
      created_at: { [require('sequelize').Op.lte]: cutoff },
    },
    raw: true,
  });
};

const getCampaignsDueFor24hrOffer = async () => {
  const delayMs = process.env.NODE_ENV === 'production'
    ? 24 * 60 * 60 * 1000  // 24 hours production
    : 3 * 60 * 1000;       // 3 minutes testing

  const cutoff = new Date(Date.now() - delayMs);

  return model.tbl_chatbot_campaigns.findAll({
    where: {
      campaign_status: 'active',
      offer_24hr_sent: 0,
      created_at: { [require('sequelize').Op.lte]: cutoff },
    },
    raw: true,
  });
};

const mark2hrSent = async (campaignId) => {
  await model.tbl_chatbot_campaigns.update(
    { reminder_2hr_sent: 1, reminder_2hr_at: new Date() },
    { where: { id: campaignId } }
  );
};

const mark24hrSent = async (campaignId) => {
  await model.tbl_chatbot_campaigns.update(
    { offer_24hr_sent: 1, offer_24hr_at: new Date() },
    { where: { id: campaignId } }
  );
};


/**
 * Log any event to tbl_chatbot_logs
 * log_type: 'lead' | 'ticket' | 'payment' | 'host' | 'campaign_sent'
 */
const logEvent = async ({ sessionId, phone, type, data, channel = 'web' }) => {
  try {
    await model.tbl_chatbot_logs.create({
      log_session_id: sessionId || null,
      log_phone: phone || null,
      log_type: type,
      log_data: data || {},
      log_channel: channel,
    });
  } catch (err) {
    console.error('[LeadService] logEvent error:', err.message);
  }
};

/**
 * Export all leads as array (for Excel download endpoint)
 */
const getLeadsForExport = async ({ from, to, status } = {}) => {
  const { Op } = require('sequelize');
  const where = {};
  if (status) where.lead_status = status;
  if (from || to) {
    where.created_at = {};
    if (from) where.created_at[Op.gte] = new Date(from);
    if (to) where.created_at[Op.lte] = new Date(to);
  }

  const rows = await model.tbl_chatbot_leads.findAll({ where, raw: true });

  return rows.map((r) => ({
    Name: r.lead_name || 'N/A',
    Phone: r.lead_phone || 'N/A',
    City: r.lead_city || 'N/A',
    'Check-in': r.lead_checkin || 'N/A',
    'Check-out': r.lead_checkout || 'N/A',
    Guests: r.lead_guests || 'N/A',
    Interest: r.lead_interest || 'property_search',
    Status: r.lead_status || 'new',
    Channel: r.lead_channel || 'web',
    Booked: r.lead_booked ? 'Yes' : 'No',
    'Booked At': r.lead_booked_at || 'N/A',
    'Created At': r.created_at,
  }));
};

/**
 * Export all logs as array (tickets, payments, etc.)
 */
const getLogsForExport = async ({ type, from, to } = {}) => {
  const { Op } = require('sequelize');
  const where = {};
  if (type) where.log_type = type;
  if (from || to) {
    where.created_at = {};
    if (from) where.created_at[Op.gte] = new Date(from);
    if (to) where.created_at[Op.lte] = new Date(to);
  }

  return model.tbl_chatbot_logs.findAll({ where, raw: true });
};

module.exports = {
  captureLead,
  markLeadBooked,
  startCampaign,
  stopCampaign,
  getCampaignsDueFor2hrReminder,
  getCampaignsDueFor24hrOffer,
  mark2hrSent,
  mark24hrSent,
  logEvent,
  getLeadsForExport,
  getLogsForExport,
};
