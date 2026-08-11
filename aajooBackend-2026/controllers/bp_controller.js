const { randomUUID } = require('crypto');
const model = require('../models');
const commonConfig = require('../config/commonConfig');
const moduleConfig = require('../config/moduleConfigs');
const services = require('../utils/chatbotServices');
const leadService = require('../utils/leadService');
const e = require('express');
const { v2: cloudinaryV2 } = require('cloudinary');
const path = require('path');
const fs = require('fs');
const os = require('os');

const ALLOWED_CASE_CATEGORIES = new Set([
  'emergency',
  'emergency_host',
  'finance_guest',
  'finance_host',
  'host_ticket',
  'on_ground',
  'general_support',
  'H1_general_support',
]);

const BOTPENGUIN_CASE_CATEGORY_MAP = {
  'urgent issue': 'emergency',
  'emergency': 'emergency',
  'room issue': 'host_ticket',
  'host not responding': 'host_ticket',
  // ADD THESE:
  'housekeeping': 'host_ticket',
  'maintenance': 'host_ticket',
  'property support': 'host_ticket',
  'booking help': 'general_support',
  'general question': 'general_support',
  'complaint': 'general_support',
  'finance': 'finance_guest',
  'payment issue': 'finance_guest',
  'host urgent': 'emergency_host',
  'host emergency': 'emergency_host',
};

const formatINR = (amount) => {
  const value = Number(amount || 0);
  return `₹${new Intl.NumberFormat('en-IN').format(value)}`;
};

const trimText = (text, maxLen = 1000) => {
  if (!text) return '';
  return text.length > maxLen ? `${text.slice(0, maxLen - 3)}...` : text;
};

const success = (res, data = {}, status = true) => {
  return res.status(commonConfig.successStatus).json({
    success: status,
    data,
  });
};

const error = (res, message, status = commonConfig.errorStatus, redirect_node = null) => {
  return res.status(status).json({
    success: false,
    message,
    redirect_node
  });
};

const normalizeChannelType = (channelType) => {
  if (!channelType || typeof channelType !== 'string') return 'web';
  const normalizedChannelType = channelType.trim().toLowerCase();
  return ['app', 'web', 'whatsapp'].includes(normalizedChannelType) ? normalizedChannelType : 'web';
};

const getValidBookingId = (bookingId, bookingIdManual) => {
  // Helper function to validate and extract valid booking ID
  // Handles cases where value might be '{}', empty string, or other invalid values
  const isValidId = (val) => {
    if (!val || typeof val !== 'string') return false;
    const trimmed = String(val).trim();
    if (!trimmed || trimmed === '{}' || trimmed === '{""}' || trimmed === 'null') return false;
    return true;
  };

  if (isValidId(bookingId)) return bookingId.trim();
  if (isValidId(bookingIdManual)) return bookingIdManual.trim();
  return null;
};

const authorizeBotPenguin = (req, res) => {
  const token = req.headers['x-botpenguin-token'];
  const expected = process.env.BOTPENGUIN_API_TOKEN;

  if (!expected) {
    error(res, 'BOTPENGUIN_API_TOKEN is not configured in env', 500);
    return false;
  }

  if (!token || String(token) !== String(expected)) {
    error(res, 'Unauthorized', 401);
    return false;
  }

  return true;
};

const safeContext = (session) => {
  if (!session || !session.cs_context) return {};
  if (typeof session.cs_context === 'object') return session.cs_context;
  try {
    return JSON.parse(session.cs_context);
  } catch (err) {
    return {};
  }
};

const getSessionById = async (sessionId) => {
  if (!sessionId) return null;
  return model.tbl_chatbot_sessions.findOne({ where: { cs_session_id: sessionId } });
};

const getUserByPhone = async (phone) => {
  if (!phone) return null;
  return model.tbl_user.findOne({
    where: { user_pnumber: phone },
    attributes: ['user_id'],
    raw: true,
  });
};

const getOrCreateSessionByPhone = async ({ phone, channelType }) => {
  await model.tbl_chatbot_sessions.sync();

  const normalizedChannelType = normalizeChannelType(channelType);

  let session = await model.tbl_chatbot_sessions.findOne({
    where: {
      cs_phone: phone,
      cs_channel_type: normalizedChannelType,
    },
    order: [['updated_at', 'DESC']],
  });

  if (session) return session;

  session = await model.tbl_chatbot_sessions.create({
    cs_session_id: randomUUID(),
    cs_channel_type: normalizedChannelType,
    cs_phone: phone,
    cs_language_pref: 'en',
    cs_stage: 'language_selection',
    cs_context: {
      booking_context: null,
      bookings: [],
      cases: [],
      channel_detected: normalizedChannelType,
    },
  });

  return session;
};

const resolveUserId = async ({ session, phone, userId }) => {
  if (userId) {
    const parsed = Number(userId);
    if (!Number.isNaN(parsed) && parsed > 0) return parsed;
  }
  if (session?.cs_user_id) {
    const parsed = Number(session.cs_user_id);
    if (!Number.isNaN(parsed) && parsed > 0) return parsed;
  }

  const userByPhone = await getUserByPhone(phone || session?.cs_phone);
  if (!userByPhone) return null;

  if (session && !session.cs_user_id) {
    await session.update({ cs_user_id: userByPhone.user_id });
  }

  const parsed = Number(userByPhone.user_id);
  return Number.isNaN(parsed) ? null : parsed;
};

const detectBookingContext = (bookings = []) => {
  const validBookings = bookings.filter((b) => Number(b?.status_id) !== Number(commonConfig.statusBookingCancelled));
  if (!validBookings.length) return 'no_booking';
  if (validBookings.some((b) => b.booking_window === 'ongoing')) return 'ongoing_stay';
  if (validBookings.some((b) => b.booking_window === 'upcoming')) return 'upcoming_stay';
  if (validBookings.some((b) => b.booking_window === 'completed')) return 'completed_stay';
  return 'no_booking';
};

const choosePrimaryBooking = (bookings = []) => {
  const validBookings = bookings.filter((b) => Number(b?.status_id) !== Number(commonConfig.statusBookingCancelled));

  return validBookings.find((b) => b.booking_window === 'ongoing')
    || validBookings.find((b) => b.booking_window === 'upcoming')
    || validBookings.find((b) => b.booking_window === 'completed')
    || validBookings[0]
    || null;
};

const persistSessionContext = async (session, nextContext = {}) => {
  if (!session) return;
  await session.update({ cs_context: nextContext });
};

const buildBookingCaseContext = async ({ session, userId, phone }) => {
  const bookings = userId ? await services.getUserBookings({ userId }) : [];
  const bookingContext = detectBookingContext(bookings);
  const primary = choosePrimaryBooking(bookings);
  const openCases = await services.checkOpenCases({
    phone,
    sessionContext: safeContext(session),
  });
  const openCase = openCases[0] || null;

  if (session) {
    const nextContext = {
      ...safeContext(session),
      booking_context: bookingContext,
      bookings,
      primary_booking: primary,
      open_cases: openCases,
    };
    await persistSessionContext(session, nextContext);
  }

  return {
    booking_context: bookingContext,
    booking_id: primary?.booking_id || null,
    property_name: primary?.property_name || null,
    property_id: primary?.property_id || null,
    open_case_id: openCase?.case_id || null,
    open_case_status: openCase?.status || null,
  };
};

const getSlaByCategory = (category) => {
  if (category === 'emergency' || category === 'emergency_host') return 'Immediate';
  if (category === 'finance_guest' || category === 'finance_host') return '2 hours';
  if (category === 'host_ticket') return '10 minutes';
  if (category === 'on_ground') return '15 minutes';
  return 'Standard SLA';
};

const normalizeCaseCategory = (category) => {
  if (!category || typeof category !== 'string') return null;

  const normalizedCategory = category
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  return BOTPENGUIN_CASE_CATEGORY_MAP[normalizedCategory] || null;
};

const MONTH_INDEX = {
  jan: 0,
  feb: 1,
  mar: 2,
  apr: 3,
  may: 4,
  jun: 5,
  jul: 6,
  aug: 7,
  sep: 8,
  oct: 9,
  nov: 10,
  dec: 11,
};

const buildValidDate = (year, monthIndex, day) => {
  const parsedYear = Number(year);
  const parsedDay = Number(day);
  if (!Number.isInteger(parsedYear) || !Number.isInteger(parsedDay)) return null;

  const date = new Date(parsedYear, monthIndex, parsedDay);
  if (Number.isNaN(date.getTime())) return null;
  if (date.getFullYear() !== parsedYear || date.getMonth() !== monthIndex || date.getDate() !== parsedDay) return null;

  return date;
};

const parseSearchDate = (value) => {
  if (!value || typeof value !== 'string') {
    return { isValid: false, message: 'Date is required.' };
  }

  const trimmedValue = value.trim();
  if (!trimmedValue) {
    return { isValid: false, message: 'Date is required.' };
  }

  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());

  let parsedDate = null;
  const shortMatch = trimmedValue.match(/^(\d{1,2})\s+([A-Za-z]{3,9})(?:\s+(\d{4}))?$/);

  if (shortMatch) {
    const [, dayText, monthText, yearText] = shortMatch;
    const monthIndex = MONTH_INDEX[monthText.slice(0, 3).toLowerCase()];
    if (monthIndex === undefined) {
      return { isValid: false, message: `Invalid date: ${trimmedValue}` };
    }

    const currentYear = todayStart.getFullYear();
    const candidateYears = yearText ? [Number(yearText)] : [currentYear, currentYear + 1];

    for (const candidateYear of candidateYears) {
      const candidateDate = buildValidDate(candidateYear, monthIndex, Number(dayText));
      if (!candidateDate) continue;
      if (yearText || candidateDate >= todayStart) {
        parsedDate = candidateDate;
        break;
      }
    }
  }

  if (!parsedDate) {
    const fallbackDate = new Date(trimmedValue);
    if (!Number.isNaN(fallbackDate.getTime())) {
      parsedDate = new Date(fallbackDate.getFullYear(), fallbackDate.getMonth(), fallbackDate.getDate());
    }
  }

  if (!parsedDate || Number.isNaN(parsedDate.getTime())) {
    return { isValid: false, message: `Invalid date: ${trimmedValue}` };
  }

  if (parsedDate < todayStart) {
    return { isValid: false, message: `${trimmedValue} is a past date. Please provide a current or future date.` };
  }

  return {
    isValid: true,
    date: parsedDate,
    normalized: parsedDate.toISOString().slice(0, 10),
  };
};

const formatBookingDate = (value) => {
  if (!value) return 'N/A';

  let date = null;

  if (/^\d{2}-\d{2}-\d{4}$/.test(value)) {
    const [day, month, year] = value.split('-').map(Number);
    date = new Date(year, month - 1, day);
  } else {
    date = new Date(value);
  }

  if (!date || Number.isNaN(date.getTime())) return value;

  return date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
  });
};

const startSession = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { phone, channel_type: channelType = 'web', user_role, language } = req.body || {};
    if (!phone) return error(res, 'phone is required', 422);

    const last10Digits = phone.slice(-10);

    const normalizeRole = (role) => {
      if (!role || typeof role !== 'string') return null;
      const r = role.trim().toLowerCase();
      if (r === 'host' || r === 'होस्ट') return 'host';
      if (r === 'guest' || r === 'अतिथि') return 'guest';
      return 'guest';
    };

    const normalizedRole = normalizeRole(user_role);

    const normalizeLanguage = (lang) => {
      if (!lang || typeof lang !== 'string') return 'en';
      const l = lang.trim().toLowerCase();
      console.log('Normalized language input:', l);
      if (l === 'hi' || l === 'हिंदी') return 'hi';
      if (l === 'en' || l === 'english') return 'en';
      return 'en';
    };

    const normalizedLang = normalizeLanguage(language);
    const normalizedChannelType = normalizeChannelType(channelType);

    let session = await getOrCreateSessionByPhone({
      phone: last10Digits,
      channelType: normalizedChannelType,
    });

    if (session) {
      const nextContext = {
        ...safeContext(session),
        channel_detected: normalizedChannelType,
      };

      await session.update({
        cs_channel_type: normalizedChannelType,
        cs_user_role: normalizedRole,
        cs_phone: last10Digits,
        cs_language_pref: normalizedLang,
        cs_context: nextContext,
      });
    }

    return success(res, {
      message: 'Session started successfully.',
      session_id: session.cs_session_id,
      user_role: normalizedRole,
      language: normalizedLang,
    });

  } catch (err) {
    console.error('Error in startSession:', err);
    return error(res, 'Something went wrong! Please try again later.', 500, err);
  }
};

const getSessionByPhone = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { phone, channel_type: channelType = 'whatsapp' } = req.body || {};
    if (!phone) return error(res, 'phone is required', 422);

    const last10Digits = phone.slice(-10);

    let session = await model.tbl_chatbot_sessions.findOne({
      where: { cs_phone: last10Digits, cs_channel_type: channelType },
      order: [['updated_at', 'DESC']],
    });

    if (!session) return error(res, 'Session not found for this phone number', 404);

    return success(res, {
      message: 'Session retrieved successfully.',
      session_id: session.cs_session_id,
      user_role: session.cs_user_role || null,
      language: session.cs_language_pref || 'en',
      channel_type: session.cs_channel_type || 'web',
    });

  } catch (err) {
    console.error('Error in getSessionByPhone:', err);
    return error(res, 'Something went wrong! Please try again later.', 500, err);
  }
};

const getContext = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId } = req.body || {};
    if (!sessionId) return error(res, 'session_id is required', 422);

    let session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const phone = session.cs_phone;
    let userId = null;
    let user_role_result = null;
    if (phone) {
      const last10Digits = phone.slice(-10);
      const inputUserRole = session?.cs_user_role || undefined;
      const whereClause = { user_pnumber: last10Digits };
      if (inputUserRole === 'host') {
        whereClause.user_isHost = commonConfig.isYes;
      } else if (inputUserRole === 'guest') {
        whereClause.user_isUser = commonConfig.isYes;
      }
      const userRow = await model.tbl_user.findOne({
        where: whereClause,
        attributes: ['user_id', 'user_fullName', 'user_isHost', 'user_isUser'],
        raw: true,
      });
      if (userRow) {
        userId = userRow.user_id;
        const userCredRow = await model.tbl_user_cred.findOne({
          where: {
            cred_user_id: userId,
            cred_user_isDelete: commonConfig.isNo
          },
          attributes: ['cred_user_id'],
          raw: true,
        });
        if (!userCredRow) {
          userId = null;
        }
        if (userRow.user_isHost) {
          user_role_result = 'host';
        } else if (userRow.user_isUser) {
          user_role_result = 'guest';
        }
      }

      if (userId && session && session.cs_user_id !== userId) {
        await session.update({ cs_user_id: userId, cs_user_name: userRow.user_fullName || 'Guest' });
      }
    }

    if (!userId) {
      return error(res, 'User not found for the provided phone number', 404);
    }

    const contextPayload = await buildBookingCaseContext({
      session,
      userId,
      phone,
    });

    return success(res, {
      ...contextPayload,
      user_role: user_role_result || session?.cs_user_role || null,
      user_id: userId || null,
      otp_verified: session?.cs_otp_verified || false,
    });
  } catch (err) {
    return error(res, 'Something went wrong! Please try again later.', 500, err);
  }
};

const searchListings = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, city, checkin, checkout, guests, page = 1, limit = 1 } = req.body || {};
    if (!sessionId) return error(res, 'session_id is required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    let itemsPerPage;
    if (session.cs_channel_type === 'whatsapp') {
      itemsPerPage = 1;
    } else {
      itemsPerPage = 5;
    }

    let listingsText = '';
    let redirect_node = null;
    let parsedCheckIn = null;
    let parsedCheckOut = null;
    let prop_image = null;
    let pagination_result = null;
    let has_more = false;
    let next_page = null;
    let req_status = false;

    if (checkin) {
      parsedCheckIn = parseSearchDate(checkin);
      if (!parsedCheckIn.isValid) {
        redirect_node = 'checkin';
        listingsText += `Invalid check-in date. ${parsedCheckIn.message}\n`;
      }
    }

    if (checkout) {
      parsedCheckOut = parseSearchDate(checkout);
      if (!parsedCheckOut.isValid) {
        redirect_node = 'checkout';
        listingsText += `Invalid check-out date. ${parsedCheckOut.message}\n`;
      }
    }

    if (
      (parsedCheckIn && !parsedCheckIn.isValid) ||
      (parsedCheckOut && !parsedCheckOut.isValid)
    ) {
      // return error(res, listingsText.trim(), 422, redirect_node);
      return success(res, {
        listings_status: false,
        listings_text: listingsText.trim(),
        redirect_node
      }, false);
    }

    if (
      parsedCheckIn?.date &&
      parsedCheckOut?.date &&
      parsedCheckOut.date < parsedCheckIn.date
    ) {
      // return error(res, 'checkout must be the same as or after checkin', 422, 'checkout');
      redirect_node = 'checkout';
      return success(res, {
        listings_status: false,
        listings_text: 'Check-out date must be the same as or after check-in date.',
        redirect_node
      }, false);
    }

    const { listings = [], pagination } = await services.listTopProperties({
      city,
      checkIn: parsedCheckIn?.normalized || checkin,
      checkOut: parsedCheckOut?.normalized || checkout,
      guests,
      page,
      limit: itemsPerPage,
    });

    const isWeb = session.cs_channel_type === 'web';

    if (listings.length > 0) {
      req_status = true;
      redirect_node = null;

      listingsText = trimText(
        listings
          .map((item, idx) =>
            `${idx + 1}. ${item.name}\n` +
            `💰 ${formatINR(item.price_per_night)}/night  ⭐ ${item.rating || 'N/A'}  📍 ${item.city || 'N/A'}` +
            (isWeb && item.image ? `\n🖼 Photo: ${item.image}` : '')
          )
          .join('\n\n')
      );

      prop_image = listings[0]?.image || null;
      pagination_result = pagination;
      has_more = pagination?.has_more || false;
      next_page = pagination?.next_page || null;

    } else {
      listingsText = 'No properties found for your search.';
      req_status = false;
      redirect_node = 'guest_menu';
    }

    if (req_status) {
      try {
        await leadService.captureLead({
          sessionId,
          name: session.cs_user_name || 'Guest',
          phone: session.cs_phone,
          city,
          checkin: parsedCheckIn?.normalized || checkin,
          checkout: parsedCheckOut?.normalized || checkout,
          guests,
          channel: session.cs_channel_type || 'web',
        });

        await leadService.startCampaign({
          sessionId,
          phone: session.cs_phone,
          city,
          channel: session.cs_channel_type || 'web',
        });

        await leadService.logEvent({
          sessionId,
          phone: session.cs_phone,
          type: 'lead',
          data: { city, checkin, checkout, guests },
          channel: session.cs_channel_type || 'web',
        });
      } catch (leadErr) {
        console.error('[searchListings] lead capture error:', leadErr.message);
      }
    }

    return success(res, {
      listings_status: req_status,
      listings_text: listingsText,
      prop_image,
      pagination: pagination_result,
      has_more,
      next_page,
      redirect_node
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const getBookingDetails = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id, booking_id_manual } = req.body || {};

    // Get valid booking ID, handling cases where value might be '{}'
    const bookingId = getValidBookingId(booking_id, booking_id_manual);

    if (!sessionId || !bookingId) return error(res, 'session_id and booking_id (or booking_id_manual) are required', 422);

    const session = await getSessionById(sessionId);
    const userId = await resolveUserId({ session });

    const details = await services.getBookingDetails({ bookingId, userId });
    if (!details) return success(res, {
      details_text: 'Booking details not found.',
      booking_id: bookingId,
      property_id: null,
    });

    const bookingRow = await model.tbl_bookings.findOne({
      where: { book_id: bookingId },
      attributes: ['book_prop_id'],
      raw: true,
    });

    const detailsText = trimText(
      `Here are your booking details:\n● 📌 Booking ID: ${details.booking_id || bookingId}\n● 🏠 Property: ${details.property_name || 'N/A'}\n● 📅 Check-in: ${formatBookingDate(details.check_in)}\n● 📅 Check-out: ${formatBookingDate(details.check_out)}\n● ✅ Status: ${details.status || 'N/A'}`
    );

    return success(res, {
      details_text: detailsText,
      booking_id: details.booking_id,
      property_id: bookingRow?.book_prop_id || null,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const getBookingPolicy = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id, booking_id_manual } = req.body || {};

    const bookingId = getValidBookingId(booking_id, booking_id_manual);
    if (!sessionId || !bookingId) return error(res, 'session_id and booking_id (or booking_id_manual) are required', 422);

    const session = await getSessionById(sessionId);
    const userId = await resolveUserId({ session });

    const policy = await services.getBookingPolicy({ bookingId, userId });
    if (!policy) return success(res, {
      policy_text: 'Booking policy not found.',
      refund_eligibility: 'N/A',
    });

    return success(res, {
      policy_text: trimText(policy.policy_text),
      refund_eligibility: `${policy.refund_eligibility_percent}%`,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const createHousekeepingRequest = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, request_type } = req.body || {};
    if (!sessionId) return error(res, 'session_id is required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const validTypes = ['room_cleaning', 'extra_towels', 'maintenance', 'other'];
    const normalizedType = (request_type || 'other').toLowerCase().replace(/\s+/g, '_');
    const finalType = validTypes.includes(normalizedType) ? normalizedType : 'other';

    const created = await services.createCase({
      sessionContext: safeContext(session),
      category: 'host_ticket',
      priority: 'normal',
      note: `Housekeeping request: ${finalType}`,
    });

    await persistSessionContext(session, created.nextContext);

    return success(res, {
      case_id: created.newCase.case_id,
      message: `Your ${finalType.replace(/_/g, ' ')} request has been sent. Our team will assist you shortly.`,
      sla: '30 minutes',
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const modifyBooking = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id: bookingId, action } = req.body || {};
    if (!sessionId || !bookingId || !action) {
      return error(res, 'session_id, booking_id and action are required', 422);
    }

    const normalizedAction = String(action).trim().toLowerCase().replace(/\s+/g, '_');

    if (!['change_dates', 'cancel_booking'].includes(normalizedAction)) {
      return error(res, 'action must be change_dates or cancel_booking', 422);
    }

    const session = await getSessionById(sessionId);
    const userId = await resolveUserId({ session });
    const result = await services.modifyOrCancelBooking({ bookingId, userId, action: normalizedAction });

    if (!result.success) {
      return success(res, {
        success: false,
        message: result.message || 'Unable to process your request.',
        booking_context: null,
        booking_id: null,
        property_name: null,
        property_id: null,
        open_case_id: null,
        open_case_status: null,
        refund_text: result.refund_text ?? null,
        refund_amount: result.refund_amount ?? null,
        refund_expected_by: result.refund_expected_by ?? null,
      });
    }

    const contextPayload = await buildBookingCaseContext({
      session,
      userId,
      phone: session?.cs_phone || null,
    });

    if (result.success) {
      try {
        await leadService.markLeadBooked({
          sessionId,
          phone: session.cs_phone,
        });

        await leadService.logEvent({
          sessionId,
          phone: session.cs_phone,
          type: 'booking_created',
          data: { booking_id: bookingId, action: normalizedAction },
          channel: session.cs_channel_type || 'web',
        });
      } catch (leadErr) {
        console.error('[modifyBooking] campaign stop error:', leadErr.message);
      }
    }

    return success(res, {
      success: true,
      message: result.message,
      ...contextPayload,
      refund_text: result.refund_text ?? null,
      refund_amount: result.refund_amount ?? null,
      refund_expected_by: result.refund_expected_by ?? null,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const sendOtp = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, otp_action } = req.body || {};
    if (!sessionId || !otp_action) return error(res, 'session_id and otp_action are required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const phone = session.cs_phone;
    const userId = await resolveUserId({ session });

    if (session && session.cs_otp_verified === true) {
      return success(res, {
        success: true,
        verified: true,
        message: 'OTP already verified for this session.',
      });
    }

    const userDetails = userId ? await model.tbl_user_cred.findOne({ where: { cred_user_id: userId }, attributes: ['cred_username', 'cred_user_email'], raw: true }) : null;

    const userDetailsFormatted = {
      email: userDetails?.cred_user_email || null,
      name: userDetails?.cred_username || 'User',
    };
    const otp = await services.sendOtp({ phone, userDetails: userDetailsFormatted, contextKey: sessionId, userId });

    await persistSessionContext(session, {
      ...safeContext(session),
      failure_attempts: 0,
    });

    return success(res, {
      success: otp.sent === true,
      verified: false,
      message: otp.message || 'OTP sent successfully.',
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const verifyOtp = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, otp } = req.body || {};
    if (!sessionId || !otp) return error(res, 'session_id and otp are required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const verify = await services.verifyOtp({ contextKey: sessionId, otp });
    const failureAttempts = verify.verified ? 0 : Number(verify.attempts || 0);

    await persistSessionContext(session, {
      ...safeContext(session),
      failure_attempts: failureAttempts,
    });

    return success(res, {
      verified: verify.verified === true,
      failure_attempts: failureAttempts,
      message: verify.verified ? 'OTP verified successfully.' : verify.reason || 'OTP verification failed.',
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const checkTransaction = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id, booking_id_manual } = req.body || {};

    const bookingId = getValidBookingId(booking_id, booking_id_manual);

    if (!sessionId || !bookingId) return error(res, 'session_id and booking_id (or booking_id_manual) are required', 422);

    const session = await getSessionById(sessionId);
    const tx = await services.checkTransaction({ bookingId });

    let caseId = null;

    if (tx.mismatch) {
      const caseResp = await services.createCase({
        sessionContext: safeContext(session),
        category: 'finance_guest',
        priority: 'high',
        note: `Payment mismatch detected for booking ID ${bookingId}. Please investigate the transaction details and resolve the issue with the guest.`,
      });
      caseId = caseResp.newCase.case_id;
      await persistSessionContext(session, caseResp.nextContext);
    }

    let message = tx.mismatch ? `Your request #${caseId} has been created ✅.\n Our finance team will get back to you within 2 hours` : 'Transaction looks good.';

    try {
      await leadService.logEvent({
        sessionId,
        phone: session.cs_phone,
        type: 'payment',
        data: { booking_id: bookingId, mismatch: tx.mismatch, case_id: caseId },
        channel: session.cs_channel_type || 'web',
      });
    } catch (e) { }

    return success(res, {
      status_text: tx.status_text || tx.status || 'unknown',
      case_id: caseId,
      message,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const refundStatus = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id: bookingId } = req.body || {};
    if (!sessionId || !bookingId) return error(res, 'session_id and booking_id are required', 422);

    const session = await getSessionById(sessionId);
    const userId = await resolveUserId({ session });

    const refund = await services.getRefundStatus({ bookingId, userId });
    if (!refund) {
      return success(res, {
        refund_text: 'Refund details not found or refund not initiated yet.',
      });
    }

    // Check if refund amount is 0 or less
    if (!refund.refund_amount || Number(refund.refund_amount) <= 0) {
      return success(res, {
        refund_text: 'No refund amount available for this booking.',
        refund_amount: 0,
      });
    }

    console.log(refund);

    return success(res, {
      refund_text: trimText(`Refund Amount: ${formatINR(refund.refund_amount)}\nExpected by: ${refund.expected_by}`),
      refund_amount: refund.refund_amount,
      refund_percent: refund.refund_percent || 0,
      expected_by: refund.expected_by || null,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const propertyLocation = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, property_id: propertyId } = req.body || {};
    if (!sessionId || !propertyId) return error(res, 'session_id and property_id are required', 422);

    const location = await services.getPropertyLocation({ propertyId });
    if (!location) return success(res, {
      location_text: 'Location details not available for this property.',
    });

    return success(res, {
      location_text: trimText(
        `📍 ${location.property_name || 'Property'}\n${location.address || 'Address unavailable'}\nCheck-in Time: ${location.check_in_time || 'N/A'}\n${location.map_link || ''}`
      ),
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const getAmenities = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, property_id: propertyId } = req.body || {};
    if (!sessionId || !propertyId) return error(res, 'session_id and property_id are required', 422);

    const amenities = await services.getAmenities({ propertyId });
    const hasWifi = amenities.some((item) => /wifi|wi-fi/i.test(item));

    return success(res, {
      wifi_name: hasWifi ? process.env.AAJAO_WIFI_NAME : null,
      wifi_password: hasWifi ? process.env.AAJAO_WIFI_PASSWORD : null,
      amenities_text: trimText(
        amenities.length ? `Amenities:\n${amenities.join(', ')}` : 'No amenities found for this property.'
      ),
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const getInvoice = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, booking_id: bookingId } = req.body || {};
    if (!sessionId || !bookingId) return error(res, 'session_id and booking_id are required', 422);

    const invoice = await services.getInvoiceDownload({ bookingId });
    const invoiceUrl = invoice.invoice_url
      ? (invoice.invoice_url.startsWith('http')
        ? invoice.invoice_url
        : `${req.protocol}://${req.get('host')}${invoice.invoice_url}`)
      : null;

    return success(res, {
      invoice_text: trimText(invoiceUrl ? 'Here is your invoice download link.' : 'Invoice is not ready yet.'),
      invoice_status: invoice.status,
      invoice_url: invoiceUrl,
      cloudinary_invoice_url: invoice.cloudinary_invoice_url || null,
      invoice_note: invoice.note || null,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const createCase = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, category, priority = 'normal' } = req.body || {};
    if (!sessionId || !category) return error(res, 'session_id and category are required', 422);

    const mappedCategory = normalizeCaseCategory(category);

    if (!mappedCategory || !ALLOWED_CASE_CATEGORIES.has(mappedCategory)) {
      return error(res, 'Invalid category', 422);
    }

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const created = await services.createCase({
      sessionContext: safeContext(session),
      category: mappedCategory,
      priority,
      note: `Case created for ${category} issue. Please investigate and resolve the issue with the customer.`,
    });

    await persistSessionContext(session, created.nextContext);

    try {
      await leadService.logEvent({
        sessionId,
        phone: session.cs_phone,
        type: 'ticket',
        data: { case_id: created.newCase.case_id, category: mappedCategory },
        channel: session.cs_channel_type || 'web',
      });
    } catch (e) { }

    return success(res, {
      case_id: created.newCase.case_id,
      message: `Case #${created.newCase.case_id} created successfully.`,
      category: mappedCategory,
      sla: getSlaByCategory(mappedCategory),
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const closeCase = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, case_id: caseId } = req.body || {};
    if (!sessionId || !caseId) return error(res, 'session_id and case_id are required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const closed = await services.closeCase({
      sessionContext: safeContext(session),
      caseId,
    });

    if (!closed.success) {
      return error(res, 'Case not found', 404);
    }

    await persistSessionContext(session, closed.nextContext);

    return success(res, {
      case_id: closed.closedCase.case_id,
      status: closed.closedCase.status,
      message: `Case #${closed.closedCase.case_id} marked as resolved.`,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const analyzeSession = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, message, category } = req.body || {};
    if (!sessionId || !message) return error(res, 'session_id and message are required', 422);

    const session = await getSessionById(sessionId);
    if (!session) return error(res, 'Session not found', 404);

    const analysis = await services.analyzeConversation({
      message,
      category,
      sessionContext: safeContext(session),
    });

    await session.update({
      cs_last_intent: analysis.last_intent,
      cs_sentiment_score: analysis.sentiment_score,
      cs_urgency_score: analysis.urgency_score,
      cs_context: analysis.nextContext,
    });

    const intentReplies = {
      emergency_support: '🚨 This sounds urgent. Connecting you to our priority team immediately.',
      host_response_issue: 'We understand your host is not responding. Let us help you right away.',
      room_issue: 'We are sorry about the room issue. Our team will look into this immediately.',
      booking_modify: 'I can help you modify your booking. Please use the Modify/Cancel option from the main menu.',
      booking_cancel: 'I can help you cancel your booking. Please use the Modify/Cancel option from the main menu.',
      refund_query: 'For refund status, please use the Refund Status option from the completed stay menu.',
      payment_issue: 'For payment issues, please use the Payment Issue option from the menu.',
      invoice_request: 'For invoices, please use the Invoice option from the completed stay menu.',
      property_location: 'For check-in location, please use the Check-in help option from the ongoing stay menu.',
      amenities_query: 'For WiFi and amenities, please use the Room Issue option from the ongoing stay menu.',
      general_support: 'Thank you for your question. Let me connect you to our support team who can help you better.',
    };

    const replyText = intentReplies[analysis.last_intent] || intentReplies.general_support;
    const needsEscalation = analysis.urgency_score >= 0.8 || analysis.sentiment_score <= 0.3;

    return success(res, {
      session_id: sessionId,
      reply_text: replyText,
      intent: analysis.last_intent,
      sentiment_score: analysis.sentiment_score,
      sentiment_label: analysis.sentiment_label,
      urgency_score: analysis.urgency_score,
      urgency_label: analysis.urgency_label,
      needs_escalation: needsEscalation,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const hostListing = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, host_id: userId } = req.body || {};
    if (!sessionId || !userId) return error(res, 'session_id and host_id are required', 422);

    const properties = await model.tbl_properties.findAll({
      where: { property_host_id: userId, is_active: commonConfig.isYes, is_deleted: commonConfig.isNo },
      attributes: ['property_id', 'property_name', 'property_address', 'property_price'],
      order: [['created_at', 'DESC']],
      limit: 1,
      raw: true,
    });

    const property = properties[0];
    if (!property) {
      return success(res, {
        listing_text: 'No listing found. Please add your first listing.',
        completion_percent: 0,
      });
    }

    const imageCount = await model.tbl_attachments.count({
      where: {
        afile_type: moduleConfig.property_image_type,
        afile_record_id: property.property_id,
      },
    });

    const amenityCount = await model.tbl_prop_to_amenities.count({
      where: { pa_prop_id: property.property_id },
    });

    const checks = [
      Boolean(property.property_name),
      Boolean(property.property_address),
      Boolean(property.property_price),
      imageCount >= 3,
      amenityCount >= 3,
    ];

    const completionPercent = Math.round((checks.filter(Boolean).length / checks.length) * 100);
    const missing = [];
    if (imageCount < 3) missing.push(`${3 - imageCount} photos`);
    if (amenityCount < 3) missing.push('amenities update');

    return success(res, {
      listing_text: trimText(
        `Listing: ${property.property_name}\nCompletion: ${completionPercent}%${missing.length ? `\nMissing: ${missing.join(', ')}` : '\nAll essentials completed.'}`
      ),
      completion_percent: completionPercent,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const hostCalendar = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, host_id: userId } = req.body || {};
    if (!sessionId || !userId) return error(res, 'session_id and host_id are required', 422);

    const rows = await services.getCalendarView({ hostId: userId });
    const calendarText = trimText(
      rows.length
        ? rows.map((item, idx) => `${idx + 1}. ${item.booking_id} | ${item.property_name || 'N/A'} | ${item.from || 'N/A'} - ${item.to || 'N/A'}`).join('\n')
        : 'No upcoming bookings found.'
    );

    return success(res, { calendar_text: calendarText });
  } catch (err) {
    return error(res, err.message);
  }
};

const hostPayout = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, host_id: userId } = req.body || {};
    if (!sessionId || !userId) return error(res, 'session_id and host_id are required', 422);

    const session = await getSessionById(sessionId);
    const payout = await services.getPayoutStatus({ hostId: userId });

    let caseId = null;
    if (payout.delayed && session) {
      const created = await services.createCase({
        sessionContext: safeContext(session),
        category: 'finance_host',
        priority: 'high',
        note: 'Payout delayed',
      });
      caseId = created.newCase.case_id;
      await persistSessionContext(session, created.nextContext);
    }

    return success(res, {
      payout_text: trimText(
        `💸 Payout: ${formatINR(payout.payout_amount)}\nExpected: ${payout.expected_date || 'TBD'}\nCommission: ${formatINR(payout.commission || 0)}`
      ),
      case_id: caseId,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const hostAnalytics = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, host_id: userId } = req.body || {};
    if (!sessionId || !userId) return error(res, 'session_id and host_id are required', 422);

    const analytics = await services.getAnalytics({ hostId: userId });

    return success(res, {
      analytics_text: trimText(
        `📊 Occupancy: ${analytics.occupancy}%\nCity Average: ${analytics.city_average}%\n💡 Suggestion: ${analytics.suggestion}`
      ),
    });
  } catch (err) {
    return error(res, err.message);
  }
};

const logSupportEvent = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, type, data } = req.body || {};
    if (!sessionId || !type) return error(res, 'session_id and type are required', 422);

    const validTypes = ['ticket', 'payment', 'host', 'lead', 'booking_created', 'campaign_sent'];
    if (!validTypes.includes(type)) return error(res, `type must be one of: ${validTypes.join(', ')}`, 422);

    const session = await getSessionById(sessionId);
    const phone = session?.cs_phone;

    await leadService.logEvent({
      sessionId,
      phone,
      type,
      data: data || {},
      channel: session?.cs_channel_type || 'web',
    });

    return success(res, { message: 'Event logged.' });
  } catch (err) {
    return error(res, err.message);
  }
};

// ─── EXCEL EXPORT ENDPOINTS ────────────────────────────────────────────────────

const exportLeads = async (req, res) => {
  try {
    const adminToken = req.headers['x-admin-token'];
    const expected = process.env.ADMIN_API_TOKEN || process.env.BOTPENGUIN_API_TOKEN;
    if (!adminToken || adminToken !== expected) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { from, to, status } = req.query;
    const leads = await leadService.getLeadsForExport({ from, to, status });

    return res.status(200).json({
      success: true,
      count: leads.length,
      data: leads,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

const exportLogs = async (req, res) => {
  try {
    const adminToken = req.headers['x-admin-token'];
    const expected = process.env.ADMIN_API_TOKEN || process.env.BOTPENGUIN_API_TOKEN;
    if (!adminToken || adminToken !== expected) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { type, from, to } = req.query;
    const logs = await leadService.getLogsForExport({ type, from, to });

    return res.status(200).json({
      success: true,
      count: logs.length,
      data: logs,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

const hostGuestIssues = async (req, res) => {
  try {
    if (!authorizeBotPenguin(req, res)) return;

    const { session_id: sessionId, host_id, user_id } = req.body || {};
    const hostId = host_id || user_id;

    if (!sessionId || !hostId) {
      return error(res, 'session_id and host_id are required', 422);
    }

    const bookings = await model.tbl_bookings.findAll({
      where: { book_host_id: hostId },
      include: [
        {
          model: model.tbl_book_details,
          as: 'bookDetails',
          attributes: ['bt_book_from', 'bt_book_to'],
        },
        {
          model: model.tbl_properties,
          as: 'bookingProperty',
          attributes: ['property_name', 'property_city'],
        },
        {
          model: model.tbl_user,
          as: 'userDetails',
          attributes: ['user_fullName'],
        },
      ],
      order: [['book_added_at', 'DESC']],
      limit: 100,
    });

    if (!bookings.length) {
      return success(res, {
        report_text: 'No bookings found. Guest issues report is empty.',
        csv_url: null,
        total_issues: 0,
      });
    }

    const bookingIds = bookings.map((b) => b.book_id);

    const sessions = await model.tbl_chatbot_sessions.findAll({
      where: {},
      attributes: ['cs_session_id', 'cs_phone', 'cs_context', 'cs_user_id', 'created_at'],
      raw: true,
    });

    const guestIssues = [];

    for (const session of sessions) {
      let context = {};
      try {
        context = typeof session.cs_context === 'string'
          ? JSON.parse(session.cs_context)
          : (session.cs_context || {});
      } catch {
        continue;
      }

      const cases = Array.isArray(context.cases) ? context.cases : [];
      if (!cases.length) {
        continue;
      }

      const allContextBookings = context.bookings || [];
      const relevantBookings = [];

      if (context.primary_booking?.booking_id) {
        relevantBookings.push(context.primary_booking);
      }

      for (const ctxBooking of allContextBookings) {
        if (ctxBooking?.booking_id && !relevantBookings.find(b => b.booking_id === ctxBooking.booking_id)) {
          relevantBookings.push(ctxBooking);
        }
      }

      let hasHostBooking = false;
      let hostBookingInfo = null;

      for (const ctxBooking of relevantBookings) {
        if (bookingIds.includes(ctxBooking.booking_id)) {
          hasHostBooking = true;
          hostBookingInfo = ctxBooking;
          break;
        }
      }

      if (!hasHostBooking) {
        continue;
      }

      const matchedBooking = bookings.find(
        (b) => String(b.book_id) === String(hostBookingInfo.booking_id)
      );

      for (const c of cases) {
        guestIssues.push({
          case_id: c.case_id || 'N/A',
          category: c.category || 'N/A',
          priority: c.priority || 'normal',
          status: c.status || 'in_progress',
          note: c.note || '',
          guest_phone: session.cs_phone || 'N/A',
          guest_name: matchedBooking?.toJSON?.()?.userDetails?.user_fullName || hostBookingInfo?.guest_name || 'N/A',
          booking_id: hostBookingInfo.booking_id || 'N/A',
          property_name: matchedBooking?.toJSON?.()?.bookingProperty?.property_name || hostBookingInfo?.property_name || 'N/A',
          property_city: matchedBooking?.toJSON?.()?.bookingProperty?.property_city || hostBookingInfo?.property_city || 'N/A',
          check_in: matchedBooking?.toJSON?.()?.bookDetails?.bt_book_from || hostBookingInfo?.check_in || 'N/A',
          check_out: matchedBooking?.toJSON?.()?.bookDetails?.bt_book_to || hostBookingInfo?.check_out || 'N/A',
          created_at: c.created_at || 'N/A',
        });
      }
    }

    const csvHeaders = [
      'Case ID',
      'Category',
      'Priority',
      'Status',
      'Note',
      'Guest Name',
      'Guest Phone',
      'Booking ID',
      'Property Name',
      'City',
      'Check-in',
      'Check-out',
      'Created At',
    ];

    const escapeCsvValue = (val) => {
      const str = String(val ?? 'N/A');
      if (str.includes(',') || str.includes('"') || str.includes('\n')) {
        return `"${str.replace(/"/g, '""')}"`;
      }
      return str;
    };

    const csvRows = [
      csvHeaders.join(','),
      ...guestIssues.map((issue) =>
        [
          escapeCsvValue(issue.case_id),
          escapeCsvValue(issue.category),
          escapeCsvValue(issue.priority),
          escapeCsvValue(issue.status),
          escapeCsvValue(issue.note),
          escapeCsvValue(issue.guest_name),
          escapeCsvValue(issue.guest_phone),
          escapeCsvValue(issue.booking_id),
          escapeCsvValue(issue.property_name),
          escapeCsvValue(issue.property_city),
          escapeCsvValue(issue.check_in),
          escapeCsvValue(issue.check_out),
          escapeCsvValue(issue.created_at),
        ].join(',')
      ),
    ];

    const csvContent = csvRows.join('\n');

    const totalIssues = guestIssues.length;
    const openIssues = guestIssues.filter((i) => i.status !== 'resolved').length;
    const resolvedIssues = totalIssues - openIssues;

    let csvUrl = null;
    if (totalIssues > 0) {
      const timestamp = Date.now();
      const fileName = `guest_issues_host_${hostId}_${timestamp}.csv`;
      const tempFilePath = path.join(os.tmpdir(), fileName);

      fs.writeFileSync(tempFilePath, csvContent, 'utf8');

      try {
        const uploadResult = await cloudinaryV2.uploader.upload(tempFilePath, {
          resource_type: 'raw',
          folder: 'aajoo_reports',
          public_id: `guest_issues_host_${hostId}_${timestamp}`,
          format: 'csv',
        });

        csvUrl = uploadResult.secure_url || uploadResult.url || null;
      } catch (uploadErr) {
        console.error('[hostGuestIssues] Cloudinary upload error:', uploadErr.message);
      } finally {
        try { fs.unlinkSync(tempFilePath); } catch { }
      }
    }

    const reportText = trimText(
      totalIssues === 0
        ? 'No guest issues found for your properties.'
        : `📋 Guest Issues Report\n` +
        `Total: ${totalIssues} | Open: ${openIssues} | Resolved: ${resolvedIssues}\n` +
        (csvUrl
          ? `\n📥 Download full report: \n\n ${csvUrl}`
          : `\nReport generation failed. Please try again.`)
    );

    return success(res, {
      report_text: reportText,
      csv_url: csvUrl,
      total_issues: totalIssues,
      open_issues: openIssues,
      resolved_issues: resolvedIssues,
    });
  } catch (err) {
    return error(res, err.message);
  }
};

module.exports = {
  startSession,
  getSessionByPhone,
  getContext,
  searchListings,
  getBookingDetails,
  getBookingPolicy,
  createHousekeepingRequest,
  modifyBooking,
  sendOtp,
  verifyOtp,
  checkTransaction,
  refundStatus,
  propertyLocation,
  getAmenities,
  getInvoice,
  createCase,
  closeCase,
  analyzeSession,
  hostListing,
  hostCalendar,
  hostPayout,
  hostAnalytics,
  logSupportEvent,
  exportLeads,
  exportLogs,
  hostGuestIssues,
};
