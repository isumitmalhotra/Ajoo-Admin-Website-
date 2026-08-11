'use strict';

const TABLE_NAME_MAP = {
  tbl_user: 'tbl_users',
  tbl_book_status: 'tbl_book_statuses',
  tbl_property_detail: 'tbl_property_details',
  tbl_prop_to_cat: 'tbl_prop_to_cats',
  tbl_prop_to_tag: 'tbl_prop_to_tags',
  tbl_book_history: 'tbl_book_histories',
  tbl_blog: 'tbl_blogs',
  tbl_blog_to_category: 'tbl_blog_to_categories',
  tbl_blog_to_tag: 'tbl_blog_to_tags',
  tbl_saved_liked_prop: 'tbl_saved_liked_props',
  tbl_payment: 'tbl_payments',
  tbl_user_cred: 'tbl_user_creds',
  tbl_user_login_auth: 'tbl_user_login_auths',
  tbl_user_otp: 'tbl_user_otps',
  tbl_user_notification: 'tbl_user_notifications',
  tbl_send_email: 'tbl_send_emails',
  tbl_forget_pass_otp: 'tbl_forget_pass_otps',
  tbl_notify_device: 'tbl_notify_devices',
  tbl_platform_review: 'tbl_platform_reviews',
  tbl_host_review: 'tbl_host_reviews',
  tbl_host_review_for_user: 'tbl_host_review_for_users',
  tbl_payout_req: 'tbl_payout_reqs',
  tbl_payout_history: 'tbl_payout_histories',
  tbl_doc_list: 'tbl_doc_lists',
  tbl_user_kyc_docs: 'user_kyc_docs'
};

const resolveTableName = (tableName) => TABLE_NAME_MAP[tableName] || tableName;
const tableDefinitionCache = new Map();

async function describeTableIfExists(queryInterface, tableName) {
  const resolvedTableName = resolveTableName(tableName);

  if (tableDefinitionCache.has(resolvedTableName)) {
    return tableDefinitionCache.get(resolvedTableName);
  }

  try {
    const definition = await queryInterface.describeTable(resolvedTableName);
    tableDefinitionCache.set(resolvedTableName, definition);
    return definition;
  } catch (error) {
    tableDefinitionCache.set(resolvedTableName, null);
    return null;
  }
}

async function addConstraintIfPossible(queryInterface, tableName, options) {
  const sourceTable = resolveTableName(tableName);
  const targetTable = resolveTableName(options.references?.table);
  const sourceDefinition = await describeTableIfExists(queryInterface, sourceTable);
  const targetDefinition = await describeTableIfExists(queryInterface, targetTable);

  if (!sourceDefinition || !targetDefinition) {
    return;
  }

  const fields = options.fields || [];
  if (fields.some(field => !sourceDefinition[field])) {
    return;
  }

  if (options.references?.field && !targetDefinition[options.references.field]) {
    return;
  }

  try {
    await addConstraintIfPossible(queryInterface, sourceTable, {
      ...options,
      references: {
        ...options.references,
        table: targetTable
      }
    });
  } catch (error) {
    const errorCode = error.original?.code;
    const errorMessage = error.message || '';

    if (
      errorCode === 'ER_DUP_KEYNAME' ||
      errorCode === 'ER_FK_DUP_NAME' ||
      /already exists|Duplicate|errno: 121/i.test(errorMessage)
    ) {
      return;
    }

    throw error;
  }
}

async function removeConstraintIfExists(queryInterface, tableName, constraintName) {
  try {
    await removeConstraintIfExists(queryInterface, resolveTableName(tableName), constraintName);
  } catch (error) {
    const errorMessage = error.message || '';

    if (/missing|doesn't exist|unknown/i.test(errorMessage)) {
      return;
    }

    throw error;
  }
}

module.exports = {
  async up(queryInterface, Sequelize) {
    // Add FK constraints for tbl_properties
    await addConstraintIfPossible(queryInterface, 'tbl_properties', {
      fields: ['property_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_properties_property_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_bookings
    await addConstraintIfPossible(queryInterface, 'tbl_bookings', {
      fields: ['book_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_bookings_book_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_bookings', {
      fields: ['book_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_bookings_book_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_bookings', {
      fields: ['book_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_bookings_book_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_property_detail
    await addConstraintIfPossible(queryInterface, 'tbl_property_detail', {
      fields: ['propDetail_propId'],
      type: 'foreign key',
      name: 'fk_tbl_property_detail_propDetail_propId',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_prop_to_cat
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_cat', {
      fields: ['pt_cat_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_cat_pt_cat_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_cat', {
      fields: ['pt_cat_cat_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_cat_pt_cat_cat_id',
      references: {
        table: 'tbl_categories',
        field: 'cat_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_prop_to_amenities
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_amenities', {
      fields: ['pa_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_amenities_pa_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_amenities', {
      fields: ['pa_amn_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_amenities_pa_amn_id',
      references: {
        table: 'tbl_amenities',
        field: 'amn_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_prop_to_tag
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_tag', {
      fields: ['pt_tag_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_tag_pt_tag_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_prop_to_tag', {
      fields: ['pt_tag_tag_id'],
      type: 'foreign key',
      name: 'fk_tbl_prop_to_tag_pt_tag_tag_id',
      references: {
        table: 'tbl_tags',
        field: 'tag_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_reviews
    await addConstraintIfPossible(queryInterface, 'tbl_reviews', {
      fields: ['br_propId'],
      type: 'foreign key',
      name: 'fk_tbl_reviews_br_propId',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_reviews', {
      fields: ['br_userId'],
      type: 'foreign key',
      name: 'fk_tbl_reviews_br_userId',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_reviews', {
      fields: ['br_hostId'],
      type: 'foreign key',
      name: 'fk_tbl_reviews_br_hostId',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_saved_liked_prop
    await addConstraintIfPossible(queryInterface, 'tbl_saved_liked_prop', {
      fields: ['slp_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_saved_liked_prop_slp_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_saved_liked_prop', {
      fields: ['slp_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_saved_liked_prop_slp_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_book_history
    await addConstraintIfPossible(queryInterface, 'tbl_book_history', {
      fields: ['bh_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_book_history_bh_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_book_history', {
      fields: ['bh_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_book_history_bh_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_book_history', {
      fields: ['bh_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_book_history_bh_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_book_details
    await addConstraintIfPossible(queryInterface, 'tbl_book_details', {
      fields: ['bd_book_id'],
      type: 'foreign key',
      name: 'fk_tbl_book_details_bd_book_id',
      references: {
        table: 'tbl_bookings',
        field: 'book_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_book_status
    await addConstraintIfPossible(queryInterface, 'tbl_book_status', {
      fields: ['bs_book_id'],
      type: 'foreign key',
      name: 'fk_tbl_book_status_bs_book_id',
      references: {
        table: 'tbl_bookings',
        field: 'book_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_payment
    await addConstraintIfPossible(queryInterface, 'tbl_payment', {
      fields: ['pay_userId'],
      type: 'foreign key',
      name: 'fk_tbl_payment_pay_userId',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_payment', {
      fields: ['pay_propId'],
      type: 'foreign key',
      name: 'fk_tbl_payment_pay_propId',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_payment', {
      fields: ['pay_hostId'],
      type: 'foreign key',
      name: 'fk_tbl_payment_pay_hostId',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_payment', {
      fields: ['pay_bookId'],
      type: 'foreign key',
      name: 'fk_tbl_payment_pay_bookId',
      references: {
        table: 'tbl_bookings',
        field: 'book_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_cred
    await addConstraintIfPossible(queryInterface, 'tbl_user_cred', {
      fields: ['uc_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_cred_uc_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_login_auth
    await addConstraintIfPossible(queryInterface, 'tbl_user_login_auth', {
      fields: ['ula_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_login_auth_ula_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_pass_auths
    await addConstraintIfPossible(queryInterface, 'tbl_user_pass_auths', {
      fields: ['upa_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_pass_auths_upa_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_otp
    await addConstraintIfPossible(queryInterface, 'tbl_user_otp', {
      fields: ['uo_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_otp_uo_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_notification
    await addConstraintIfPossible(queryInterface, 'tbl_user_notification', {
      fields: ['un_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_notification_un_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_blog_to_category
    await addConstraintIfPossible(queryInterface, 'tbl_blog_to_category', {
      fields: ['btc_blog_id'],
      type: 'foreign key',
      name: 'fk_tbl_blog_to_category_btc_blog_id',
      references: {
        table: 'tbl_blog',
        field: 'blog_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_blog_to_category', {
      fields: ['btc_cat_id'],
      type: 'foreign key',
      name: 'fk_tbl_blog_to_category_btc_cat_id',
      references: {
        table: 'tbl_blog_categories',
        field: 'blog_cat_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_blog_to_tag
    await addConstraintIfPossible(queryInterface, 'tbl_blog_to_tag', {
      fields: ['btt_blog_id'],
      type: 'foreign key',
      name: 'fk_tbl_blog_to_tag_btt_blog_id',
      references: {
        table: 'tbl_blog',
        field: 'blog_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_blog_to_tag', {
      fields: ['btt_tag_id'],
      type: 'foreign key',
      name: 'fk_tbl_blog_to_tag_btt_tag_id',
      references: {
        table: 'tbl_blog_tags',
        field: 'blog_tag_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_review_likes
    await addConstraintIfPossible(queryInterface, 'tbl_review_likes', {
      fields: ['rl_review_id'],
      type: 'foreign key',
      name: 'fk_tbl_review_likes_rl_review_id',
      references: {
        table: 'tbl_reviews',
        field: 'br_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_host_earnings
    await addConstraintIfPossible(queryInterface, 'tbl_host_earnings', {
      fields: ['he_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_earnings_he_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_host_earnings', {
      fields: ['he_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_earnings_he_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_host_acc_details
    await addConstraintIfPossible(queryInterface, 'tbl_host_acc_details', {
      fields: ['had_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_acc_details_had_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_payout_req
    await addConstraintIfPossible(queryInterface, 'tbl_payout_req', {
      fields: ['pr_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_payout_req_pr_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_payout_history
    await addConstraintIfPossible(queryInterface, 'tbl_payout_history', {
      fields: ['ph_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_payout_history_ph_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_payout_history', {
      fields: ['ph_req_id'],
      type: 'foreign key',
      name: 'fk_tbl_payout_history_ph_req_id',
      references: {
        table: 'tbl_payout_req',
        field: 'pr_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_messages
    await addConstraintIfPossible(queryInterface, 'tbl_messages', {
      fields: ['msg_sender_id'],
      type: 'foreign key',
      name: 'fk_tbl_messages_msg_sender_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_messages', {
      fields: ['msg_receiver_id'],
      type: 'foreign key',
      name: 'fk_tbl_messages_msg_receiver_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_messages', {
      fields: ['msg_prop_id'],
      type: 'foreign key',
      name: 'fk_tbl_messages_msg_prop_id',
      references: {
        table: 'tbl_properties',
        field: 'property_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_negotiation_offers
    await addConstraintIfPossible(queryInterface, 'tbl_negotiation_offers', {
      fields: ['no_msg_id'],
      type: 'foreign key',
      name: 'fk_tbl_negotiation_offers_no_msg_id',
      references: {
        table: 'tbl_messages',
        field: 'msg_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_negotiation_offers', {
      fields: ['no_sender_id'],
      type: 'foreign key',
      name: 'fk_tbl_negotiation_offers_no_sender_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_negotiation_offers', {
      fields: ['no_receiver_id'],
      type: 'foreign key',
      name: 'fk_tbl_negotiation_offers_no_receiver_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_nagotiate_messages
    await addConstraintIfPossible(queryInterface, 'tbl_nagotiate_messages', {
      fields: ['nm_offer_id'],
      type: 'foreign key',
      name: 'fk_tbl_nagotiate_messages_nm_offer_id',
      references: {
        table: 'tbl_negotiation_offers',
        field: 'no_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_nagotiate_messages', {
      fields: ['nm_sender_id'],
      type: 'foreign key',
      name: 'fk_tbl_nagotiate_messages_nm_sender_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_nagotiate_messages', {
      fields: ['nm_receiver_id'],
      type: 'foreign key',
      name: 'fk_tbl_nagotiate_messages_nm_receiver_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_doc_list
    await addConstraintIfPossible(queryInterface, 'tbl_doc_list', {
      fields: ['dl_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_doc_list_dl_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_user_kyc_docs
    await addConstraintIfPossible(queryInterface, 'tbl_user_kyc_docs', {
      fields: ['ukd_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_kyc_docs_ukd_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_user_kyc_docs', {
      fields: ['ukd_doc_id'],
      type: 'foreign key',
      name: 'fk_tbl_user_kyc_docs_ukd_doc_id',
      references: {
        table: 'tbl_doc_list',
        field: 'dl_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_send_email
    await addConstraintIfPossible(queryInterface, 'tbl_send_email', {
      fields: ['se_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_send_email_se_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_forget_pass_otp
    await addConstraintIfPossible(queryInterface, 'tbl_forget_pass_otp', {
      fields: ['fpo_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_forget_pass_otp_fpo_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_notify_device
    await addConstraintIfPossible(queryInterface, 'tbl_notify_device', {
      fields: ['nd_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_notify_device_nd_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_platform_review
    await addConstraintIfPossible(queryInterface, 'tbl_platform_review', {
      fields: ['pr_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_platform_review_pr_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_host_review
    await addConstraintIfPossible(queryInterface, 'tbl_host_review', {
      fields: ['hr_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_review_hr_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_host_review', {
      fields: ['hr_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_review_hr_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_host_review_for_user
    await addConstraintIfPossible(queryInterface, 'tbl_host_review_for_user', {
      fields: ['hr_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_review_for_user_hr_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
    await addConstraintIfPossible(queryInterface, 'tbl_host_review_for_user', {
      fields: ['hr_host_id'],
      type: 'foreign key',
      name: 'fk_tbl_host_review_for_user_hr_host_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_admins
    await addConstraintIfPossible(queryInterface, 'tbl_admins', {
      fields: ['admin_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_admins_admin_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_history
    await addConstraintIfPossible(queryInterface, 'tbl_history', {
      fields: ['h_user_id'],
      type: 'foreign key',
      name: 'fk_tbl_history_h_user_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });

    // Add FK constraints for tbl_blog
    await addConstraintIfPossible(queryInterface, 'tbl_blog', {
      fields: ['blog_author_id'],
      type: 'foreign key',
      name: 'fk_tbl_blog_blog_author_id',
      references: {
        table: 'tbl_user',
        field: 'user_id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
  },

  async down(queryInterface, Sequelize) {
    // Remove all FK constraints in reverse order
    await removeConstraintIfExists(queryInterface, 'tbl_blog', 'fk_tbl_blog_blog_author_id');
    await removeConstraintIfExists(queryInterface, 'tbl_history', 'fk_tbl_history_h_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_admins', 'fk_tbl_admins_admin_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_review_for_user', 'fk_tbl_host_review_for_user_hr_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_review_for_user', 'fk_tbl_host_review_for_user_hr_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_review', 'fk_tbl_host_review_hr_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_review', 'fk_tbl_host_review_hr_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_platform_review', 'fk_tbl_platform_review_pr_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_notify_device', 'fk_tbl_notify_device_nd_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_forget_pass_otp', 'fk_tbl_forget_pass_otp_fpo_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_send_email', 'fk_tbl_send_email_se_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_kyc_docs', 'fk_tbl_user_kyc_docs_ukd_doc_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_kyc_docs', 'fk_tbl_user_kyc_docs_ukd_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_doc_list', 'fk_tbl_doc_list_dl_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_nagotiate_messages', 'fk_tbl_nagotiate_messages_nm_receiver_id');
    await removeConstraintIfExists(queryInterface, 'tbl_nagotiate_messages', 'fk_tbl_nagotiate_messages_nm_sender_id');
    await removeConstraintIfExists(queryInterface, 'tbl_nagotiate_messages', 'fk_tbl_nagotiate_messages_nm_offer_id');
    await removeConstraintIfExists(queryInterface, 'tbl_negotiation_offers', 'fk_tbl_negotiation_offers_no_receiver_id');
    await removeConstraintIfExists(queryInterface, 'tbl_negotiation_offers', 'fk_tbl_negotiation_offers_no_sender_id');
    await removeConstraintIfExists(queryInterface, 'tbl_negotiation_offers', 'fk_tbl_negotiation_offers_no_msg_id');
    await removeConstraintIfExists(queryInterface, 'tbl_messages', 'fk_tbl_messages_msg_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_messages', 'fk_tbl_messages_msg_receiver_id');
    await removeConstraintIfExists(queryInterface, 'tbl_messages', 'fk_tbl_messages_msg_sender_id');
    await removeConstraintIfExists(queryInterface, 'tbl_payout_history', 'fk_tbl_payout_history_ph_req_id');
    await removeConstraintIfExists(queryInterface, 'tbl_payout_history', 'fk_tbl_payout_history_ph_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_payout_req', 'fk_tbl_payout_req_pr_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_acc_details', 'fk_tbl_host_acc_details_had_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_earnings', 'fk_tbl_host_earnings_he_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_host_earnings', 'fk_tbl_host_earnings_he_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_review_likes', 'fk_tbl_review_likes_rl_review_id');
    await removeConstraintIfExists(queryInterface, 'tbl_blog_to_tag', 'fk_tbl_blog_to_tag_btt_tag_id');
    await removeConstraintIfExists(queryInterface, 'tbl_blog_to_tag', 'fk_tbl_blog_to_tag_btt_blog_id');
    await removeConstraintIfExists(queryInterface, 'tbl_blog_to_category', 'fk_tbl_blog_to_category_btc_cat_id');
    await removeConstraintIfExists(queryInterface, 'tbl_blog_to_category', 'fk_tbl_blog_to_category_btc_blog_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_notification', 'fk_tbl_user_notification_un_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_otp', 'fk_tbl_user_otp_uo_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_pass_auths', 'fk_tbl_user_pass_auths_upa_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_login_auth', 'fk_tbl_user_login_auth_ula_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_user_cred', 'fk_tbl_user_cred_uc_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_payment', 'fk_tbl_payment_pay_bookId');
    await removeConstraintIfExists(queryInterface, 'tbl_payment', 'fk_tbl_payment_pay_hostId');
    await removeConstraintIfExists(queryInterface, 'tbl_payment', 'fk_tbl_payment_pay_propId');
    await removeConstraintIfExists(queryInterface, 'tbl_payment', 'fk_tbl_payment_pay_userId');
    await removeConstraintIfExists(queryInterface, 'tbl_book_status', 'fk_tbl_book_status_bs_book_id');
    await removeConstraintIfExists(queryInterface, 'tbl_book_details', 'fk_tbl_book_details_bd_book_id');
    await removeConstraintIfExists(queryInterface, 'tbl_book_history', 'fk_tbl_book_history_bh_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_book_history', 'fk_tbl_book_history_bh_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_book_history', 'fk_tbl_book_history_bh_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_saved_liked_prop', 'fk_tbl_saved_liked_prop_slp_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_saved_liked_prop', 'fk_tbl_saved_liked_prop_slp_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_reviews', 'fk_tbl_reviews_br_hostId');
    await removeConstraintIfExists(queryInterface, 'tbl_reviews', 'fk_tbl_reviews_br_userId');
    await removeConstraintIfExists(queryInterface, 'tbl_reviews', 'fk_tbl_reviews_br_propId');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_tag', 'fk_tbl_prop_to_tag_pt_tag_tag_id');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_tag', 'fk_tbl_prop_to_tag_pt_tag_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_amenities', 'fk_tbl_prop_to_amenities_pa_amn_id');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_amenities', 'fk_tbl_prop_to_amenities_pa_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_cat', 'fk_tbl_prop_to_cat_pt_cat_cat_id');
    await removeConstraintIfExists(queryInterface, 'tbl_prop_to_cat', 'fk_tbl_prop_to_cat_pt_cat_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_property_detail', 'fk_tbl_property_detail_propDetail_propId');
    await removeConstraintIfExists(queryInterface, 'tbl_bookings', 'fk_tbl_bookings_book_host_id');
    await removeConstraintIfExists(queryInterface, 'tbl_bookings', 'fk_tbl_bookings_book_prop_id');
    await removeConstraintIfExists(queryInterface, 'tbl_bookings', 'fk_tbl_bookings_book_user_id');
    await removeConstraintIfExists(queryInterface, 'tbl_properties', 'fk_tbl_properties_property_host_id');
  }
};

