const { Op } = require('sequelize');
const model = require('../models');
const commonConfig = require('../config/commonConfig');
const moduleConfig = require('../config/moduleConfigs');
const { sendOtpEmail } = require('./common');
const { generateInvoicePDF } = require('./invoiceGenerator');
const { CloudinaryManager } = require('./cloudinary');
const path = require('path');
const fs = require('fs');

const SERVICE_NAME = {
  LISTINGS_SERVICE: 'LISTINGS_SERVICE',
  BOOKING_SERVICE: 'BOOKING_SERVICE',
  PAYMENT_SERVICE: 'PAYMENT_SERVICE',
  DOCUMENT_SERVICE: 'DOCUMENT_SERVICE',
  PROPERTY_SERVICE: 'PROPERTY_SERVICE',
  CALENDAR_SERVICE: 'CALENDAR_SERVICE',
  PAYOUT_SERVICE: 'PAYOUT_SERVICE',
  ANALYTICS_SERVICE: 'ANALYTICS_SERVICE',
  SUPPORT_SERVICE: 'SUPPORT_SERVICE',
  OTP_SERVICE: 'OTP_SERVICE',
};

const memoryOtpStore = new Map();

const formatINR = (amount) => {
  const value = Number(amount || 0);
  return `Rs.${new Intl.NumberFormat('en-IN').format(value)}`;
};

const roundAmount = (amount) => Number((Number(amount || 0)).toFixed(2));

const calculateCancellationRefund = ({ paidAmount, checkInDate }) => {
  const amount = Number(paidAmount || 0);
  if (!(amount > 0)) return null;

  const normalizedCheckInDate = normalizeDate(checkInDate);
  const now = new Date();
  const hoursDiff = normalizedCheckInDate
    ? (normalizedCheckInDate.getTime() - now.getTime()) / (1000 * 60 * 60)
    : null;

  let refundAmount = roundAmount(amount * 0.8);

  if (hoursDiff !== null && hoursDiff < 24) {
    refundAmount = roundAmount(Math.max(amount - 500, 0));
  }

  return {
    refund_amount: refundAmount,
    refund_percent: amount > 0 ? roundAmount((refundAmount / amount) * 100) : 0,
    free_cancellation_before_hours: 24,
    cancellation_fee: 500,
    expected_timeline: '5-7 days',
  };
};

const normalizeDate = (input) => {
  if (!input) return null;
  if (/^\d{2}-\d{2}-\d{4}$/.test(input)) {
    const [day, month, year] = input.split('-').map(Number);
    const d = new Date(year, month - 1, day);
    if (!Number.isNaN(d.getTime())) return d;
  }
  const d = new Date(input);
  if (!Number.isNaN(d.getTime())) return d;
  return null;
};

const classifyBookingWindow = (booking) => {
  const now = new Date();
  const from = normalizeDate(booking?.bookDetails?.bt_book_from || booking?.check_in);
  const to = normalizeDate(booking?.bookDetails?.bt_book_to || booking?.check_out);


  if (!from || !to) return 'no_booking';
  const nowDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const fromDate = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  const toDate = new Date(to.getFullYear(), to.getMonth(), to.getDate());

  if (nowDate < fromDate) return 'upcoming';
  if (nowDate >= fromDate && nowDate <= toDate) return 'ongoing';
  if (nowDate > toDate) return 'completed';
  return 'no_booking';
};

const listTopProperties = async ({ city, guests, checkIn, checkOut, page = 1, limit = 5 }) => {
  const whereClause = {
    is_active: commonConfig.isYes,
    is_deleted: commonConfig.isNo,
  };

  const parsedPage = Math.max(Number(page) || 1, 1);
  const parsedLimit = Math.max(Number(limit) || 5, 1);
  const offset = (parsedPage - 1) * parsedLimit;

  if (city) {
    whereClause.property_city = {
      [Op.like]: `%${city}%`,
    };
  }

  const { rows, count } = await model.tbl_properties.findAndCountAll({
    where: whereClause,
    attributes: [
      'property_id',
      'property_name',
      'property_city',
      'property_price',
      'property_latitude',
      'property_longitude',
    ],
    limit: parsedLimit,
    offset,
    order: [['created_at', 'DESC']],
    raw: true,
  });

  const ids = rows.map((row) => row.property_id);
  let reviews = [];
  let propertyImages = [];
  let coverImages = [];

  if (ids.length) {
    [reviews, propertyImages, coverImages] = await Promise.all([
      model.tbl_reviews.findAll({
        where: {
          br_propId: {
            [Op.in]: ids,
          },
        },
        attributes: ['br_propId', 'br_rating'],
        raw: true,
      }),
      model.tbl_attachments.findAll({
        where: {
          afile_record_id: {
            [Op.in]: ids,
          },
          afile_type: moduleConfig.property_image_type,
        },
        attributes: ['afile_record_id', 'afile_cldId'],
        raw: true,
      }),
      model.tbl_attachments.findAll({
        where: {
          afile_record_id: {
            [Op.in]: ids,
          },
          afile_type: moduleConfig.property_cover_image_type,
        },
        attributes: ['afile_record_id', 'afile_cldId'],
        raw: true,
      }),
    ]);
  }

  const ratingMap = {};
  reviews.forEach((r) => {
    const propId = r.br_propId;
    if (!ratingMap[propId]) {
      ratingMap[propId] = { sum: 0, count: 0 };
    }
    ratingMap[propId].sum += Number(r.br_rating || 0);
    ratingMap[propId].count += 1;
  });

  const cloudinaryInstance = new CloudinaryManager();

  const properties = await Promise.all(rows.map(async (row) => {
    const stats = ratingMap[row.property_id] || { sum: 0, count: 0 };
    const rating = stats.count ? Number((stats.sum / stats.count).toFixed(1)) : null;

    const matchingImages = propertyImages.filter((image) => image.afile_record_id === row.property_id);
    const matchingCoverImage = coverImages.find((image) => image.afile_record_id === row.property_id);

    const images = await Promise.all(
      matchingImages.map(async (image) => cloudinaryInstance.getOptimizedUrl(image.afile_cldId))
    );

    const cover_image = matchingCoverImage?.afile_cldId
      ? await cloudinaryInstance.getOptimizedUrl(matchingCoverImage.afile_cldId)
      : null;

    return {
      property_id: row.property_id,
      name: row.property_name,
      city: row.property_city,
      price_per_night: row.property_price,
      rating,
      distance_km: null,
      image: cover_image || images[0] || null,
      cover_image,
      images,
      guests_requested: guests || null,
      requested_checkin: checkIn || null,
      requested_checkout: checkOut || null,
    };
  }));

  return {
    listings: properties,
    pagination: {
      page: parsedPage,
      limit: parsedLimit,
      total: count,
      has_more: offset + properties.length < count,
      next_page: offset + properties.length < count ? parsedPage + 1 : null,
    },
  };
};

const getUserBookings = async ({ userId }) => {
  const rows = await model.tbl_bookings.findAll({
    where: { book_user_id: userId },
    include: [
      {
        model: model.tbl_book_details,
        as: 'bookDetails',
        attributes: ['bt_book_from', 'bt_book_to'],
      },
      {
        model: model.tbl_book_status,
        as: 'bookingStatus',
        attributes: ['bs_title', 'bs_code'],
      },
      {
        model: model.tbl_properties,
        as: 'bookingProperty',
        attributes: ['property_id', 'property_name', 'property_address', 'property_city'],
      },
    ],
    order: [['book_added_at', 'DESC']],
    limit: 10,
  });

  const payload = rows.map((booking) => {
    const row = booking.toJSON();
    return {
      booking_id: row.book_id,
      status_id: row.book_status,
      status: row.bookingStatus?.bs_title || null,
      check_in: row.bookDetails?.bt_book_from || null,
      check_out: row.bookDetails?.bt_book_to || null,
      property_id: row.bookingProperty?.property_id || null,
      property_name: row.bookingProperty?.property_name || null,
      property_address: row.bookingProperty?.property_address || null,
      property_city: row.bookingProperty?.property_city || null,
      total_amount: row.book_total_amt,
      is_paid: row.book_is_paid,
      booking_window: classifyBookingWindow(row),
    };
  });

  return payload;
};

const getBookingDetails = async ({ bookingId, userId }) => {
  const row = await model.tbl_bookings.findOne({
    where: {
      book_id: bookingId,
      ...(userId ? { book_user_id: userId } : {}),
    },
    include: [
      {
        model: model.tbl_book_details,
        as: 'bookDetails',
        attributes: ['bt_book_from', 'bt_book_to'],
      },
      {
        model: model.tbl_book_status,
        as: 'bookingStatus',
        attributes: ['bs_title', 'bs_code'],
      },
      {
        model: model.tbl_properties,
        as: 'bookingProperty',
        attributes: ['property_name', 'property_address', 'property_latitude', 'property_longitude'],
      },
    ],
  });

  if (!row) return null;

  const booking = row.toJSON();
  return {
    booking_id: booking.book_id,
    status: booking.bookingStatus?.bs_title,
    check_in: booking.bookDetails?.bt_book_from,
    check_out: booking.bookDetails?.bt_book_to,
    property_name: booking.bookingProperty?.property_name,
    property_address: booking.bookingProperty?.property_address,
    map_link:
      booking.bookingProperty?.property_latitude && booking.bookingProperty?.property_longitude
        ? `https://maps.google.com/?q=${booking.bookingProperty.property_latitude},${booking.bookingProperty.property_longitude}`
        : null,
    refund_eligibility: booking.book_is_paid ? 'partial' : 'full',
  };
};

const getBookingPolicy = async ({ bookingId, userId }) => {
  const booking = await getBookingDetails({ bookingId, userId });
  if (!booking) return null;

  const refundPercent = booking.refund_eligibility === 'partial' ? 80 : 0;

  return {
    booking_id: bookingId,
    refund_eligibility_percent: refundPercent,
    policy_text: `Here's your cancellation policy:\nRefund: 80%\nFree cancellation before: 24 hours\nCancellation fee: Rs.500`,
  };
};

const checkTransaction = async ({ bookingId, userId }) => {
  const payment = await model.tbl_payment.findOne({
    where: {
      ...(bookingId ? { pay_bookId: bookingId } : {}),
      ...(userId ? { pay_userId: userId } : {}),
    },
    order: [['pay_addedAt', 'DESC']],
    raw: true,
  });

  if (!payment) {
    return {
      found: false,
      status: 'not_found',
      mismatch: true,
    };
  }

  return {
    found: true,
    booking_id: payment.pay_bookId,
    amount: payment.pay_amount,
    status_id: payment.pay_status,
    status_text: payment.pay_status_text,
    mismatch: false,
  };
};

const getRefundStatus = async ({ bookingId, userId }) => {
  const booking = await model.tbl_bookings.findOne({
    where: {
      book_id: bookingId,
      ...(userId ? { book_user_id: userId } : {}),
    },
    include: [
      {
        model: model.tbl_book_details,
        as: 'bookDetails',
        attributes: ['bt_book_from'],
      },
    ],
    raw: false,
  });

  if (!booking) return null;

  const payment = await model.tbl_payment.findOne({
    where: {
      ...(bookingId ? { pay_bookId: bookingId } : {}),
      ...(userId ? { pay_userId: userId } : {}),
    },
    order: [['pay_addedAt', 'DESC']],
    raw: true,
  });

  if (!payment) return null;

  const refundDetails = calculateCancellationRefund({
    paidAmount: payment.pay_amount,
    checkInDate: booking.bookDetails?.bt_book_from || null,
  });

  if (!refundDetails) return null;

  return {
    booking_id: payment.pay_bookId,
    refund_amount: refundDetails.refund_amount,
    expected_by: refundDetails.expected_timeline,
    expected_timeline: refundDetails.expected_timeline,
    within_sla: true,
    refund_percent: refundDetails.refund_percent,
    free_cancellation_before_hours: refundDetails.free_cancellation_before_hours,
    cancellation_fee: refundDetails.cancellation_fee,
  };
};

const getInvoiceDownload = async ({ bookingId }) => {
  const booking = await model.tbl_bookings.findOne({
    where: { book_id: bookingId },
    include: [
      { model: model.tbl_book_details, as: 'bookDetails', attributes: ['bt_book_from', 'bt_book_to'] },
      { model: model.tbl_properties, as: 'bookingProperty', attributes: ['property_name', 'property_address'] },
      { model: model.tbl_user, as: 'userDetails', attributes: ['user_id', 'user_fullName'] },
    ],
    raw: false,
  });
  if (!booking) {
    return { booking_id: bookingId, invoice_url: null, status: 'not_found', note: 'Booking not found.' };
  }
  const payment = await model.tbl_payment.findOne({
    where: { pay_bookId: bookingId },
    order: [['pay_addedAt', 'DESC']],
    raw: true,
  });
  // Get user email
  let user_email = null;
  if (booking.userDetails) {
    const cred = await model.tbl_user_cred.findOne({
      where: { cred_user_id: booking.userDetails.user_id },
      attributes: ['cred_user_email'],
      raw: true,
    });
    user_email = cred?.cred_user_email || null;
  }
  // Prepare invoice data with more booking fields
  const invoiceData = {
    booking_id: booking.book_id,
    booking_number: booking.book_pri_id,
    user_name: booking.userDetails?.user_fullName || 'N/A',
    user_email,
    property_name: booking.bookingProperty?.property_name || 'N/A',
    property_address: booking.bookingProperty?.property_address || 'N/A',
    check_in: booking.bookDetails?.bt_book_from || 'N/A',
    check_out: booking.bookDetails?.bt_book_to || 'N/A',
    amount: booking.book_total_amt || payment?.pay_amount || 'N/A',
    price: booking.book_price || 'N/A',
    tax: booking.book_tax || 'N/A',
    tax_percent: booking.book_tax_percentagenatage || 'N/A',
    is_paid: booking.book_is_paid,
    is_cod: booking.book_is_cod,
    no_of_guests: booking.book_no_of_guests,
    no_of_beds: booking.book_no_of_beds,
    created_at: booking.book_added_at,
    updated_at: booking.book_updated_at,
  };
  // Generate PDF
  let pdfPath;
  try {
    pdfPath = await generateInvoicePDF(invoiceData);
  } catch (err) {
    return { booking_id: bookingId, invoice_url: null, status: 'error', note: 'Failed to generate PDF.' };
  }
  const localInvoiceUrl = `/invoices/${path.basename(pdfPath)}`;
  // Upload to Cloudinary
  let cloudinary_invoice_url = null;
  try {
    const cloudinaryMgr = new CloudinaryManager();
    const uploadResult = await cloudinaryMgr.uploadImage(pdfPath, 'invoice', bookingId, {
      resourceType: 'raw',
      folder: 'aajoo_invoices',
      public_id: `invoice_${bookingId}_${Date.now()}`,
      format: 'pdf',
    });
    cloudinary_invoice_url = uploadResult.secure_url || uploadResult.url || null;
  } catch (err) {
    console.error('[getInvoiceDownload] Cloudinary upload error:', err.message);
  }
  return {
    booking_id: bookingId,
    invoice_url: localInvoiceUrl,
    cloudinary_invoice_url,
    status: 'ready',
    note: cloudinary_invoice_url
      ? 'Invoice generated. Cloudinary copy uploaded and local delivery URL returned.'
      : 'Invoice generated locally. Cloudinary upload failed or PDF delivery is restricted.',
  };
};

const getPropertyLocation = async ({ propertyId }) => {
  const row = await model.tbl_properties.findOne({
    where: { property_id: propertyId },
    attributes: ['property_name', 'property_latitude', 'property_longitude', 'property_address'],
    raw: true,
  });

  if (!row) return null;

  return {
    property_name: row.property_name,
    address: row.property_address,
    check_in_time: '2 PM',
    map_link:
      row.property_latitude && row.property_longitude
        ? `https://maps.google.com/?q=${row.property_latitude},${row.property_longitude}`
        : null,
  };
};

const getAmenities = async ({ propertyId }) => {
  const rows = await model.tbl_prop_to_amenities.findAll({
    where: { pa_prop_id: propertyId },
    include: [
      {
        model: model.tbl_amenities,
        as: 'amenity',
        attributes: ['amn_title'],
      },
    ],
  });

  return rows.map((r) => r.amenity?.amn_title).filter(Boolean);
};

const getCalendarView = async ({ hostId }) => {
  const rows = await model.tbl_bookings.findAll({
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
        attributes: ['property_name'],
      },
    ],
    limit: 10,
    order: [['book_added_at', 'DESC']],
  });

  return rows.map((r) => ({
    booking_id: r.book_id,
    property_name: r.bookingProperty?.property_name || null,
    from: r.bookDetails?.bt_book_from || null,
    to: r.bookDetails?.bt_book_to || null,
  }));
};

const getPayoutStatus = async ({ hostId }) => {
  const row = await model.tbl_payout_req.findOne({
    where: { pay_req_host_id: hostId },
    order: [['pay_req_id', 'DESC']],
    raw: true,
  });

  if (!row) {
    return {
      payout_amount: 0,
      expected_date: null,
      commission: 0,
      delayed: false,
    };
  }

  return {
    payout_amount: row.pay_req_amount,
    expected_date: null,
    commission: null,
    delayed: row.pay_req_status === commonConfig.statusPayoutFailed,
    payout_status_id: row.pay_req_status,
  };
};

const getAnalytics = async ({ hostId }) => {
  const hostBookings = await model.tbl_bookings.count({ where: { book_host_id: hostId } });
  const completed = await model.tbl_bookings.count({
    where: {
      book_host_id: hostId,
      book_status: commonConfig.statusCheckout,
    },
  });

  const occupancy = hostBookings ? Number(((completed / hostBookings) * 100).toFixed(1)) : 0;

  return {
    occupancy,
    city_average: 75,
    suggestion: occupancy < 75 ? 'Reduce price by ₹300 for higher conversion.' : 'Your listing is performing near market average.',
  };
};

const checkOpenCases = async ({ sessionContext }) => {
  const openCases = (sessionContext?.cases || []).filter((c) => c.status !== 'resolved');
  return openCases;
};

const analyzeConversation = async ({ message = '', category = '', sessionContext = {} }) => {
  const normalizedMessage = String(message || '').trim();
  const normalizedText = `${normalizedMessage} ${String(category || '')}`.toLowerCase();

  const intentMatchers = [
    { intent: 'emergency_support', patterns: ['urgent issue', 'emergency', 'help immediately', 'urgent', 'asap'] },
    { intent: 'host_response_issue', patterns: ['host not responding', 'host not replying', 'host unavailable'] },
    { intent: 'room_issue', patterns: ['room issue', 'ac', 'wifi', 'cleanliness', 'noise', 'room problem'] },
    { intent: 'booking_modify', patterns: ['change booking', 'change dates', 'modify booking', 'reschedule'] },
    { intent: 'booking_cancel', patterns: ['cancel booking', 'cancel my booking'] },
    { intent: 'refund_query', patterns: ['refund', 'refund status', 'refund not received'] },
    { intent: 'payment_issue', patterns: ['payment issue', 'payment failed', 'charged twice', 'transaction'] },
    { intent: 'invoice_request', patterns: ['invoice', 'bill', 'receipt'] },
    { intent: 'property_location', patterns: ['location', 'address', 'map', 'where is property'] },
    { intent: 'amenities_query', patterns: ['amenities', 'wifi password', 'wifi', 'facilities'] },
  ];

  let detectedIntent = 'general_support';
  for (const rule of intentMatchers) {
    if (rule.patterns.some((pattern) => normalizedText.includes(pattern))) {
      detectedIntent = rule.intent;
      break;
    }
  }

  let sentimentScore = 0.5;
  const negativeSignals = ['bad', 'worst', 'terrible', 'angry', 'frustrated', 'upset', 'dirty', 'noise', 'issue', 'problem', 'not working', 'no response', 'unsafe'];
  const positiveSignals = ['good', 'great', 'thanks', 'thank you', 'awesome', 'resolved', 'fixed', 'perfect'];

  negativeSignals.forEach((signal) => {
    if (normalizedText.includes(signal)) sentimentScore -= 0.12;
  });

  positiveSignals.forEach((signal) => {
    if (normalizedText.includes(signal)) sentimentScore += 0.1;
  });

  sentimentScore = Math.max(0, Math.min(1, Number(sentimentScore.toFixed(2))));

  let urgencyScore = 0.2;
  const urgencySignals = ['urgent', 'emergency', 'immediately', 'asap', 'right now', 'now', 'host not responding', 'unsafe', 'help'];
  urgencySignals.forEach((signal) => {
    if (normalizedText.includes(signal)) urgencyScore += 0.15;
  });

  if (detectedIntent === 'emergency_support') urgencyScore = Math.max(urgencyScore, 0.95);
  if (detectedIntent === 'host_response_issue' || detectedIntent === 'room_issue') urgencyScore = Math.max(urgencyScore, 0.7);

  urgencyScore = Math.max(0, Math.min(1, Number(urgencyScore.toFixed(2))));

  const sentimentLabel = sentimentScore >= 0.7 ? 'positive' : sentimentScore <= 0.35 ? 'negative' : 'neutral';
  const urgencyLabel = urgencyScore >= 0.8 ? 'high' : urgencyScore >= 0.45 ? 'medium' : 'low';

  return {
    last_intent: detectedIntent,
    sentiment_score: sentimentScore,
    sentiment_label: sentimentLabel,
    urgency_score: urgencyScore,
    urgency_label: urgencyLabel,
    nextContext: {
      ...(sessionContext || {}),
      analysis: {
        last_message: normalizedMessage || null,
        last_intent: detectedIntent,
        sentiment_score: sentimentScore,
        sentiment_label: sentimentLabel,
        urgency_score: urgencyScore,
        urgency_label: urgencyLabel,
        analyzed_at: new Date().toISOString(),
      },
    },
  };
};

const createCase = async ({ sessionContext, category, priority = 'normal', note }) => {
  const now = Date.now();
  const caseId = `AJS-${String(now).slice(-5)}`;

  const newCase = {
    case_id: caseId,
    category,
    status: 'in_progress',
    priority,
    note,
    created_at: new Date().toISOString(),
  };

  const cases = Array.isArray(sessionContext?.cases) ? [...sessionContext.cases] : [];
  cases.push(newCase);

  return {
    newCase,
    nextContext: {
      ...(sessionContext || {}),
      cases,
    },
  };
};

const closeCase = async ({ sessionContext, caseId }) => {
  const cases = Array.isArray(sessionContext?.cases) ? [...sessionContext.cases] : [];
  const caseIndex = cases.findIndex((item) => String(item.case_id) === String(caseId));

  if (caseIndex === -1) {
    return {
      success: false,
      nextContext: sessionContext || {},
      closedCase: null,
    };
  }

  const existingCase = cases[caseIndex];
  const closedCase = {
    ...existingCase,
    status: 'resolved',
    closed_at: new Date().toISOString(),
  };

  cases[caseIndex] = closedCase;

  return {
    success: true,
    closedCase,
    nextContext: {
      ...(sessionContext || {}),
      cases,
    },
  };
};

const sendOtp = async ({ phone, userDetails = {}, contextKey, userId = null }) => {
  const { email = null, name = 'User' } = userDetails;
  const otp = String(Math.floor(100000 + Math.random() * 900000));
  memoryOtpStore.set(contextKey, {
    otp,
    phone,
    email,
    attempts: 0,
    createdAt: Date.now(),
  });

  if (email) {
    console.log(`Sending OTP ${otp} to email ${email} for context ${contextKey}`); // Debug log removed in production
    await sendOtpEmail(email, name, otp, 'Your OTP for Aajao', 'chatbot_otp', userId); // Commented out in production
  }

  return {
    sent: true,
    otp_ref: contextKey,
    message: 'OTP sent successfully to your email.',
  };
};

const verifyOtp = async ({ contextKey, otp }) => {
  const entry = memoryOtpStore.get(contextKey);
  if (!entry) return { verified: false, attempts: 0, reason: 'OTP not found' };

  entry.attempts += 1;
  if (entry.otp === String(otp)) {
    memoryOtpStore.delete(contextKey);
    return { verified: true, attempts: entry.attempts };
  }

  memoryOtpStore.set(contextKey, entry);
  return { verified: false, attempts: entry.attempts, reason: 'Invalid OTP' };
};

const modifyOrCancelBooking = async ({ bookingId, userId, action }) => {
  const booking = await model.tbl_bookings.findOne({
    where: {
      book_id: bookingId,
      ...(userId ? { book_user_id: userId } : {}),
    },
    raw: true,
  });

  if (!booking) {
    return {
      success: false,
      message: 'Booking not found',
      refund_text: null,
      refund_amount: null,
      refund_expected_by: null,
    };
  }

  if (action === 'cancel_booking') {
    await model.tbl_bookings.update(
      { book_status: commonConfig.statusBookingCancelled },
      { where: { book_id: bookingId } }
    );
    await model.tbl_book_details.update(
      { bt_book_status: commonConfig.statusBookingCancelled },
      { where: { bt_book_id: bookingId } }
    );

    const refund = await getRefundStatus({ bookingId, userId });
    const refundPayload = {
      refund_text: null,
      refund_amount: null,
      refund_expected_by: null,
    };

    let message = 'Your booking has been cancelled successfully.';

    if (refund) {
      refundPayload.refund_text = `If you have already made payment, don't worry. Refund amount ${formatINR(refund.refund_amount)} will be processed within ${refund.expected_timeline || '5-7 days'}.`;
      refundPayload.refund_amount = refund.refund_amount ?? null;
      refundPayload.refund_expected_by = refund.expected_by || null;
      message = `${message}\n${refundPayload.refund_text}`;
    }

    return {
      success: true,
      message,
      ...refundPayload,
    };
  }

  if (action === 'change_dates') {
    return {
      success: true,
      message: 'Change date request received. Our team will contact you shortly.',
      refund_text: null,
      refund_amount: null,
      refund_expected_by: null,
    };
  }

  return {
    success: false,
    message: 'Invalid action',
    refund_text: null,
    refund_amount: null,
    refund_expected_by: null,
  };
};

module.exports = {
  SERVICE_NAME,
  listTopProperties,
  getUserBookings,
  getBookingDetails,
  getBookingPolicy,
  checkTransaction,
  getRefundStatus,
  getInvoiceDownload,
  getPropertyLocation,
  getAmenities,
  getCalendarView,
  getPayoutStatus,
  getAnalytics,
  checkOpenCases,
  analyzeConversation,
  createCase,
  closeCase,
  sendOtp,
  verifyOtp,
  modifyOrCancelBooking,
};
