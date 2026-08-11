//afile types ----------------------------->
exports.user_image_type = 1;
exports.id_document_image_type = 2;
exports.blog_image_type = 3;
exports.property_image_type = 4;
exports.property_cover_image_type = 5;
exports.admin_image_type = 6;
exports.host_giver_user_review_img = 7;
exports.checkout_review_img = 8;
exports.property_doc_type = 9;

exports.cms_section_homePpage_type = 10;
exports.cms_section_FAQPage_type = 11;
exports.cms_section_TCPage_type = 12;

//OTP TYPES ----------------------------->
exports.user_forget_otp_type = 1;
//-----------------ADMIN-----------------------------
//CMS------------------>
exports.homePageFeatureSection = 1;
exports.homePageLabelSection = 2;
exports.homePageTestimonialSection = 3;
exports.FAQPageHeaderSection = 4;
exports.FAQPageContactSection = 5;
exports.FAQPageLabelSection = 6;
exports.TCHeaderSection = 7;
exports.TCPageLabelSection = 8;

//---------------RAZORPAY----------------------------------
// Razorpay credentials moved to config/payments.config.js (single source of
// truth). Require `{ razorpay } = require('./payments.config')` and read
// `razorpay.keyId / razorpay.keySecret` if you need them in a new module.
//---------------DEVICE TOKEN------------------------------
// exports.device_token = 'fCDX0lRwTqqHeM1PeQdxXG:APA91bF9LB87EkVPt60mkgeZdm0xdhoadt2k6SpN_raAZCUyLH4bmZzn0Bs3eN9hw1lILdcvRF8nmzphdXleuFrXgXGH6c_9iN6lGwLkAIU_i9pnLWE9vTw';

// WhatsApp / BotPenguin webhook verify token. Vestigial — no consumers in
// code as of 2026-06-08. Env-gated so production can rotate without a code
// push if/when chatbot webhooks are wired up. Set WHATSAPP_VERIFY_TOKEN in
// Render env to override.
exports.whats_app_verify_token = process.env.WHATSAPP_VERIFY_TOKEN || 'fCDX0lRwTqqHeM1PeQdxXG231H4bmZzn0Bs3eN9hw1lILdcvRF8nmzphdXleuFrXgXGH6c_9iN6lGwLkAIU_i9pnLW2312E9vTw';

exports.documnetTypes = [
    {
        doc_id: 1,
        doc_name: "Adhaar card"
    },
    {
        doc_id: 2,
        doc_name: "Voter card"
    },
    {
        doc_id: 3,
        doc_name: "Driving licence"
    },
];
exports.countries = [
    {
        country_name: "India",
        country_code: "IN",
        country_id: 1
    }
];
exports.state = [
    {
        state_id: 1,
        state_cntr_id: 1,
        state_name: "Himachal pradesh"
    },
    {
        state_id: 2,
        state_cntr_id: 1,
        state_name: "Punjab"
    },
    {
        state_id: 3,
        state_cntr_id: 1,
        state_name: "Uttar Pradesh"
    },
    {
        state_id: 4,
        state_cntr_id: 1,
        state_name: "Haryana"
    },
    {
        state_id: 5,
        state_cntr_id: 1,
        state_name: "Delhi"
    },
    {
        state_id: 6,
        state_cntr_id: 1,
        state_name: "J&K"
    },
];

