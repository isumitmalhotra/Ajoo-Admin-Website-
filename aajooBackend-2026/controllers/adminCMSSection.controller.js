const fs = require("fs/promises");
const model = require("../models");
const { CloudinaryManager } = require("../utils/cloudinary");
const { sequelize } = require("../models");
const { Op } = require("sequelize");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { cms_section_page_type } = require("../config/moduleConfigs");
const moduleConfigs = require("../config/moduleConfigs");
const { logAdminMutation } = require("../services/admin/adminAudit.service");

const cloudinaryManager = new CloudinaryManager();

const SECTION = {
  FEATURE: moduleConfigs.homePageFeatureSection,
  LABEL: moduleConfigs.homePageLabelSection,
  TESTIMONIAL: moduleConfigs.homePageTestimonialSection,
  FAQPageHeaderSection: moduleConfigs.FAQPageHeaderSection,
  FAQPageContactSection: moduleConfigs.FAQPageContactSection,
  FAQPageLabelSection: moduleConfigs.FAQPageLabelSection,
  TCHeaderSection: moduleConfigs.TCHeaderSection,
  TCPageLabelSection: moduleConfigs.TCPageLabelSection
};

const parseIds = (data) => {
  if (data === undefined || data === null || data === "") {
    return [];
  }

  let parsed = data;

  if (typeof parsed === "string") {
    try {
      parsed = JSON.parse(parsed);
    } catch (error) {
      return [];
    }
  }

  if (!Array.isArray(parsed)) {
    return [];
  }

  return parsed
    .map((item) => (typeof item === "object" && item !== null ? item.id : item))
    .map((item) => Number(item))
    .filter(Number.isFinite);
};

const cleanupLocalFiles = async (filePaths = []) => {
  const uniquePaths = [...new Set(filePaths.filter(Boolean))];

  await Promise.all(uniquePaths.map(async (filePath) => {
    try {
      await fs.unlink(filePath);
    } catch (error) {
      if (error.code !== "ENOENT") {
        console.error(`Failed to delete temp file ${filePath}:`, error.message);
      }
    }
  }));
};

const deleteCloudinaryAssets = async (publicIds = []) => {
  const uniqueIds = [...new Set(publicIds.filter(Boolean))];

  await Promise.all(uniqueIds.map(async (publicId) => {
    try {
      await cloudinaryManager.deleteSingleImage(publicId);
    } catch (error) {
      console.error(`Failed to delete Cloudinary asset ${publicId}:`, error.message);
    }
  }));
};

const uploadCmsImage = async (file) => {
  if (!file?.path) {
    return null;
  }

  const uploadResult = await cloudinaryManager.cloudinary.uploader.upload(file.path, {
    resource_type: "auto"
  });

  return {
    publicId: uploadResult.public_id,
    secureUrl: uploadResult.secure_url,
    originalName: file.originalname,
    tempPath: file.path
  };
};

const createAttachmentRecord = async (uploadedImage, recordId, transaction) => {
  return model.tbl_attachments.create({
    afile_type: cms_section_page_type,
    afile_record_id: recordId,
    afile_path: uploadedImage.secureUrl,
    afile_cldId: uploadedImage.publicId,
    afile_name: uploadedImage.originalName
  }, { transaction });
};

const upsertCmsSections = async ({
  cpPageId,
  sections,
  imageSectionId,
  uploadedImage,
  transaction
}) => {
  const existingRecords = await model.tbl_cms_pages.findAll({
    raw: true,
    where: {
      cp_page_id: cpPageId,
      cp_section_id: sections.map((section) => section.cp_section_id)
    },
    transaction
  });

  const existingMap = new Map(
    existingRecords.map((record) => [record.cp_section_id, record])
  );

  const stalePublicIds = [];

  if (uploadedImage && imageSectionId) {
    const existingSection = existingMap.get(imageSectionId);

    if (existingSection?.cp_afile_id) {
      const oldAttachment = await model.tbl_attachments.findOne({
        raw: true,
        where: { afile_id: existingSection.cp_afile_id },
        transaction
      });

      if (oldAttachment?.afile_cldId) {
        stalePublicIds.push(oldAttachment.afile_cldId);
      }

      await model.tbl_attachments.destroy({
        where: { afile_id: existingSection.cp_afile_id },
        transaction
      });
    }

    const attachment = await createAttachmentRecord(uploadedImage, imageSectionId, transaction);
    const imageSection = sections.find((section) => section.cp_section_id === imageSectionId);

    if (imageSection) {
      imageSection.cp_afile_id = attachment.afile_id;
    }
  }

  const results = [];

  for (const section of sections) {
    const existingSection = existingMap.get(section.cp_section_id);

    if (existingSection) {
      await model.tbl_cms_pages.update(section, {
        where: {
          cp_page_id: cpPageId,
          cp_section_id: section.cp_section_id
        },
        transaction
      });
      results.push({ section: section.cp_section_id, action: "updated" });
    } else {
      await model.tbl_cms_pages.create(section, { transaction });
      results.push({ section: section.cp_section_id, action: "created" });
    }
  }

  return { results, stalePublicIds };
};

const buildAttachmentUrlMap = async (attachmentIds = []) => {
  const uniqueAttachmentIds = [...new Set(attachmentIds.filter(Boolean))];

  if (!uniqueAttachmentIds.length) {
    return new Map();
  }

  const attachments = await model.tbl_attachments.findAll({
    raw: true,
    where: { afile_id: uniqueAttachmentIds },
    attributes: ["afile_id", "afile_cldId"]
  });

  const entries = await Promise.all(
    attachments.map(async (attachment) => [
      attachment.afile_id,
      attachment.afile_cldId
        ? await cloudinaryManager.getOptimizedUrl(attachment.afile_cldId)
        : null
    ])
  );

  return new Map(entries);
};

const addUpdateCMSSection = async (req, res) => {
  try {
    const reqData = { ...req.body };
    const sectionId = reqData.cs_id ? Number(reqData.cs_id) : null;

    if (sectionId) {
      const existingSection = await model.tbl_cms_section.findOne({
        where: { cs_id: sectionId },
        raw: true,
      });

      if (!existingSection) {
        return common.response(req, res, commonConfig.notFoundStatus, false, "CMS Section not found");
      }
    }

    const payload = {
      cs_title: reqData.cs_title,
      cs_description: reqData.cs_description,
      cs_isActive: reqData.cs_isActive,
      cs_url: reqData.cs_url,
      cs_order: reqData.cs_order,
    };

    if (sectionId) {
      await model.tbl_cms_section.update(payload, { where: { cs_id: sectionId } });
    } else {
      const createdSection = await model.tbl_cms_section.create(payload);
      await logAdminMutation(req, {
        action: "create",
        entity: "cms_section",
        entityId: createdSection.cs_id,
        after: payload,
      });
      return common.response(req, res, commonConfig.successStatus, true, "CMS Section added successfully");
    }

    await logAdminMutation(req, {
      action: "update",
      entity: "cms_section",
      entityId: sectionId,
      after: payload,
    });

    return common.response(req, res, commonConfig.successStatus, true, "CMS Section updated successfully");
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

const listingCMSSection = async (req, res) => {
  try {
    const reqData = { ...req.body };
    const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
    const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
    const offset = (page - 1) * limit;
    const search = reqData.search?.trim() || "";

    const whereClause = {};

    if (search) {
      whereClause[Op.or] = [
        { cs_title: { [Op.like]: `%${search}%` } },
        { cs_slug: { [Op.like]: `%${search}%` } }
      ];
    }

    const { count, rows } = await model.tbl_cms_section.findAndCountAll({
      raw: true,
      where: whereClause,
      limit,
      offset,
      order: [["cs_order", "ASC"]],
      attributes: ["cs_id", "cs_title", "cs_slug", "cs_isActive", "cs_url", "cs_order", "cs_created_at"]
    });

    if (!rows.length) {
      return common.response(req, res, commonConfig.successStatus, true, "No CMS Sections found");
    }

    return common.response(req, res, commonConfig.successStatus, true, "CMS Sections retrieved successfully", {
      totalRecords: count,
      currentPage: page,
      totalPages: Math.ceil(count / limit),
      search,
      page,
      limit,
      offset,
      sections: rows,
    });
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

const addUpdateHomePageCMSSection = async (req, res) => {
  let transaction;
  const uploadedImage = await uploadCmsImage(req.file);

  try {
    const { cp_page_id } = req.body;
    const properties = parseIds(req.body.properties);
    const testimonials = parseIds(req.body.testimonials);

    const sections = [
      {
        cp_page_id,
        cp_section_id: SECTION.FEATURE,
        cp_title: req.body.featureTitle,
        cp_description: req.body.featureDesc,
        cp_hm_props: properties
      },
      {
        cp_page_id,
        cp_section_id: SECTION.LABEL,
        cp_title: req.body.labelTitle,
        cp_description: req.body.labelDesc,
        cp_bt_title: req.body.buttonTitle,
        cp_btn_url: req.body.buttonUrl,
        cp_btn_opn: req.body.buttonTarget
      },
      {
        cp_page_id,
        cp_section_id: SECTION.TESTIMONIAL,
        cp_title: req.body.testimonialTitle,
        cp_description: req.body.testimonialDesc,
        cp_hm_testimonial: testimonials
      }
    ];

    transaction = await sequelize.transaction();

    const { results, stalePublicIds } = await upsertCmsSections({
      cpPageId: cp_page_id,
      sections,
      imageSectionId: SECTION.LABEL,
      uploadedImage,
      transaction
    });

    await transaction.commit();
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);
    await deleteCloudinaryAssets(stalePublicIds);
    await logAdminMutation(req, {
      action: "update",
      entity: "cms_homepage",
      entityId: cp_page_id,
      after: sections,
    });

    return common.response(req, res, 200, true, "Home CMS updated successfully", results);
  } catch (error) {
    if (transaction && !transaction.finished) {
      await transaction.rollback();
    }

    await deleteCloudinaryAssets(uploadedImage ? [uploadedImage.publicId] : []);
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);

    return common.response(req, res, 422, false, error.message);
  }
};

const getHomePageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);

    if (!cp_page_id || Number.isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }

    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });

    const recordMap = new Map(records.map((record) => [record.cp_section_id, record]));
    const featureSection = recordMap.get(SECTION.FEATURE);
    const labelSection = recordMap.get(SECTION.LABEL);
    const testimonialSection = recordMap.get(SECTION.TESTIMONIAL);

    const propertyIds = parseIds(featureSection?.cp_hm_props);
    const testimonialIds = parseIds(testimonialSection?.cp_hm_testimonial);
    const attachmentUrlMap = await buildAttachmentUrlMap(records.map((record) => record.cp_afile_id));

    const [properties, testimonials] = await Promise.all([
      propertyIds.length
        ? model.tbl_properties.findAll({
          raw: true,
          where: {
            property_id: propertyIds,
            is_active: commonConfig.isYes,
            is_deleted: commonConfig.isNo,
            is_verify: commonConfig.isYes
          },
          attributes: ["property_id", "property_name"]
        })
        : [],
      testimonialIds.length
        ? model.tbl_reviews.findAll({
          raw: true,
          where: { br_id: testimonialIds },
          attributes: ["br_id", "br_title"]
        })
        : [],
    ]);

    const propertyMap = new Map(properties.map((property) => [property.property_id, property.property_name]));
    const testimonialMap = new Map(testimonials.map((testimonial) => [testimonial.br_id, testimonial.br_title]));

    const response = {
      featureTitle: featureSection?.cp_title || "",
      featureDesc: featureSection?.cp_description || "",
      selectedProperties: propertyIds
        .map((id) => propertyMap.has(id) ? { id, name: propertyMap.get(id) } : null)
        .filter(Boolean),
      labelTitle: labelSection?.cp_title || "",
      labelDesc: labelSection?.cp_description || "",
      image: labelSection?.cp_afile_id ? attachmentUrlMap.get(labelSection.cp_afile_id) || null : null,
      buttonTitle: labelSection?.cp_bt_title || "",
      buttonUrl: labelSection?.cp_btn_url || "",
      buttonTarget: labelSection?.cp_btn_opn || "_self",
      testimonialTitle: testimonialSection?.cp_title || "",
      testimonialDesc: testimonialSection?.cp_description || "",
      selectedTestimonials: testimonialIds
        .map((id) => testimonialMap.has(id) ? { id, name: testimonialMap.get(id) } : null)
        .filter(Boolean)
    };

    return common.response(req, res, 200, true, "Home CMS fetched successfully", response);
  } catch (error) {
    return common.response(req, res, 500, false, error.message);
  }
};

const propertydropdown = async (req, res) => {
  try {
    const properties = await model.tbl_properties.findAll({
      where: {
        is_active: commonConfig.isYes,
        is_deleted: commonConfig.isNo,
        is_verify: commonConfig.isYes
      },
      attributes: ["property_id", "property_name"],
      raw: true
    });

    if (!properties.length) {
      return common.response(req, res, commonConfig.successStatus, true, "No properties found");
    }

    return common.response(req, res, commonConfig.successStatus, true, "Properties retrieved successfully", properties);
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

const testimonialDronpdown = async (req, res) => {
  try {
    const testimonials = await model.tbl_reviews.findAll({
      where: {
        br_isActive: commonConfig.isYes,
        br_isDelete: commonConfig.isNo,
      },
      attributes: ["br_id", "br_title"],
      raw: true
    });

    if (!testimonials.length) {
      return common.response(req, res, commonConfig.successStatus, true, "No testimonials found");
    }

    return common.response(req, res, commonConfig.successStatus, true, "Testimonials retrieved successfully", testimonials);
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

const deleteSingleImage = async (req, res) => {
  try {
    const { cp_page_id, cp_section_id } = req.body;
    const findRecord = await model.tbl_cms_pages.findOne({
      raw: true,
      where: {
        cp_page_id,
        cp_section_id
      },
      attributes: ["cp_afile_id"]
    });

    if (!findRecord) {
      return common.response(req, res, 404, false, "Record not found");
    }

    if (!findRecord.cp_afile_id) {
      return common.response(req, res, 404, false, "No image associated with this record");
    }

    const attachment = await model.tbl_attachments.findOne({
      raw: true,
      where: { afile_id: findRecord.cp_afile_id },
      attributes: ["afile_cldId"]
    });

    if (!attachment) {
      return common.response(req, res, 404, false, "Attachment record not found");
    }

    await cloudinaryManager.deleteSingleImage(attachment.afile_cldId);
    await model.tbl_attachments.destroy({
      where: { afile_id: findRecord.cp_afile_id }
    });
    await model.tbl_cms_pages.update(
      { cp_afile_id: null },
      { where: { cp_page_id, cp_section_id } }
    );
    await logAdminMutation(req, {
      action: "delete_image",
      entity: "cms_page_attachment",
      entityId: findRecord.cp_afile_id,
      before: {
        cp_page_id,
        cp_section_id,
        afile_id: findRecord.cp_afile_id,
        afile_cldId: attachment.afile_cldId,
      },
    });

    return common.response(req, res, 200, true, "Image deleted successfully");
  } catch (error) {
    return common.response(req, res, 500, false, "Failed to delete old image from Cloudinary");
  }
};

const addUpdateFAQPageCMS = async (req, res) => {
  let transaction;
  const uploadedImage = await uploadCmsImage(req.file);

  try {
    const { cp_page_id } = req.body;
    const sections = [
      {
        cp_page_id,
        cp_section_id: SECTION.FAQPageHeaderSection,
        cp_title: req.body.headerTitle,
        cp_description: req.body.headerDesc
      },
      {
        cp_page_id,
        cp_section_id: SECTION.FAQPageContactSection,
        cp_title: req.body.contactTitle,
        cp_description: req.body.contactDesc,
        cp_bt_title: req.body.contactBtnTitle,
        cp_btn_url: req.body.contactBtnUrl,
        cp_btn_opn: req.body.contactTarget
      },
      {
        cp_page_id,
        cp_section_id: SECTION.FAQPageLabelSection,
        cp_title: req.body.labelTitle,
        cp_description: req.body.labelDesc,
        cp_bt_title: req.body.labelBtnTitle,
        cp_btn_url: req.body.labelBtnUrl,
        cp_btn_opn: req.body.labelTarget
      }
    ];

    transaction = await sequelize.transaction();

    const { results, stalePublicIds } = await upsertCmsSections({
      cpPageId: cp_page_id,
      sections,
      imageSectionId: SECTION.FAQPageLabelSection,
      uploadedImage,
      transaction
    });

    await transaction.commit();
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);
    await deleteCloudinaryAssets(stalePublicIds);
    await logAdminMutation(req, {
      action: "update",
      entity: "cms_faq_page",
      entityId: cp_page_id,
      after: sections,
    });

    return common.response(req, res, commonConfig.successStatus, true, "FAQ CMS updated successfully", results);
  } catch (error) {
    if (transaction && !transaction.finished) {
      await transaction.rollback();
    }

    await deleteCloudinaryAssets(uploadedImage ? [uploadedImage.publicId] : []);
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);

    return common.response(req, res, commonConfig.successStatus, false, error.message);
  }
};

const getFAQPageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);

    if (!cp_page_id || Number.isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }

    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });

    const recordMap = new Map(records.map((record) => [record.cp_section_id, record]));
    const headerSection = recordMap.get(SECTION.FAQPageHeaderSection);
    const contactSection = recordMap.get(SECTION.FAQPageContactSection);
    const labelSection = recordMap.get(SECTION.FAQPageLabelSection);
    const attachmentUrlMap = await buildAttachmentUrlMap(records.map((record) => record.cp_afile_id));

    const response = {
      headerTitle: headerSection?.cp_title || "",
      headerDesc: headerSection?.cp_description || "",
      contactTitle: contactSection?.cp_title || "",
      contactDesc: contactSection?.cp_description || "",
      contactBtnTitle: contactSection?.cp_bt_title || "",
      contactBtnUrl: contactSection?.cp_btn_url || "",
      contactTarget: contactSection?.cp_btn_opn || "_self",
      labelTitle: labelSection?.cp_title || "",
      labelDesc: labelSection?.cp_description || "",
      labelBtnTitle: labelSection?.cp_bt_title || "",
      labelBtnUrl: labelSection?.cp_btn_url || "",
      labelTarget: labelSection?.cp_btn_opn || "_self",
      labelImage: labelSection?.cp_afile_id ? attachmentUrlMap.get(labelSection.cp_afile_id) || null : null
    };

    return common.response(req, res, commonConfig.successStatus, true, "FAQ CMS fetched successfully", response);
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

const addUpdateTCPageCMS = async (req, res) => {
  let transaction;
  const uploadedImage = await uploadCmsImage(req.file);

  try {
    const { cp_page_id } = req.body;
    const sections = [
      {
        cp_page_id,
        cp_section_id: SECTION.TCHeaderSection,
        cp_title: req.body.headerTitle,
        cp_description: req.body.headerDesc
      },
      {
        cp_page_id,
        cp_section_id: SECTION.TCPageLabelSection,
        cp_title: req.body.labelTitle,
        cp_description: req.body.labelDesc
      }
    ];

    transaction = await sequelize.transaction();

    const { results, stalePublicIds } = await upsertCmsSections({
      cpPageId: cp_page_id,
      sections,
      imageSectionId: SECTION.TCPageLabelSection,
      uploadedImage,
      transaction
    });

    await transaction.commit();
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);
    await deleteCloudinaryAssets(stalePublicIds);
    await logAdminMutation(req, {
      action: "update",
      entity: "cms_tc_page",
      entityId: cp_page_id,
      after: sections,
    });

    return common.response(req, res, 200, true, "TC CMS updated successfully", results);
  } catch (error) {
    if (transaction && !transaction.finished) {
      await transaction.rollback();
    }

    await deleteCloudinaryAssets(uploadedImage ? [uploadedImage.publicId] : []);
    await cleanupLocalFiles(uploadedImage ? [uploadedImage.tempPath] : []);

    return common.response(req, res, 422, false, error.message);
  }
};

const getTCPageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);

    if (!cp_page_id || Number.isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }

    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });

    const recordMap = new Map(records.map((record) => [record.cp_section_id, record]));
    const headerSection = recordMap.get(SECTION.TCHeaderSection);
    const labelSection = recordMap.get(SECTION.TCPageLabelSection);
    const attachmentUrlMap = await buildAttachmentUrlMap(records.map((record) => record.cp_afile_id));

    const response = {
      headerTitle: headerSection?.cp_title || "",
      headerDesc: headerSection?.cp_description || "",
      labelTitle: labelSection?.cp_title || "",
      labelDesc: labelSection?.cp_description || "",
      labelImage: labelSection?.cp_afile_id ? attachmentUrlMap.get(labelSection.cp_afile_id) || null : null
    };

    return common.response(req, res, 200, true, "TC CMS fetched successfully", response);
  } catch (error) {
    return common.response(req, res, 500, false, error.message);
  }
};

module.exports = {
  addUpdateCMSSection,
  listingCMSSection,
  addUpdateHomePageCMSSection,
  getHomePageCMS,
  propertydropdown,
  testimonialDronpdown,
  deleteSingleImage,
  addUpdateFAQPageCMS,
  getFAQPageCMS,
  addUpdateTCPageCMS,
  getTCPageCMS
};
