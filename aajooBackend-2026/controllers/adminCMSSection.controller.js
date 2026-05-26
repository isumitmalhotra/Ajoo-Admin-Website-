const model = require("../models");
const { CloudinaryManager } = require("../utils/cloudinary");
const { sequelize } = require("../models");
const { Op } = require("sequelize");
const cloudinaryManager = new CloudinaryManager();
const fs = require('fs');
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { cms_section_page_type } = require("../config/moduleConfigs");
const moduleConfigs = require("../config/moduleConfigs");

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
  if (!data) return [];

  const parsed = typeof data === "string" ? JSON.parse(data) : data;

  // If array of objects → extract ids
  if (parsed.length && typeof parsed[0] === "object") {
    return parsed.map(item => item.id);
  }

  // If already array of numbers
  return parsed;
};
const addUpdateCMSSection = async (req, res) => {
  try {
    const reqData = { ...req.body };
    let sectionId = reqData.cs_id ? reqData.cs_id : null;

    let payload = {
      cs_title: reqData.cs_title,
      cs_description: reqData.cs_description,
      cs_isActive: reqData.cs_isActive,
      cs_url: reqData.cs_url,
      cs_order: reqData.cs_order,
    };
    if (sectionId) {
      await model.tbl_cms_section.update(payload, { where: { cs_id: sectionId } });
    } else {
      await model.tbl_cms_section.create(payload);
    }
    return common.response(req, res, commonConfig.successStatus, true, "CMS Section added successfully");
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
    let whereClause = {};
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
      order: [['cs_order', 'ASC']],
      attributes: ['cs_id', 'cs_title', 'cs_slug', 'cs_isActive', 'cs_url', 'cs_order', 'cs_created_at']
    });
    if (rows.length === 0) {
      return common.response(req, res, commonConfig.successStatus, true, "No CMS Sections found");
    }
    const totalPages = Math.ceil(count / limit);
    return common.response(req, res, commonConfig.successStatus, true, "CMS Sections retrieved successfully", {
      totalRecords: count,
      currentPage: page,
      totalPages: totalPages,
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
  const transaction = await sequelize.transaction();
  try {
    const { cp_page_id } = req.body;
    const file = req.file; // label image
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

    const results = [];
    for (const item of sections) {
      const { cp_page_id, cp_section_id } = item;

      const existing = await model.tbl_cms_pages.findOne({
        where: { cp_page_id, cp_section_id },
        transaction
      });

      if (cp_section_id === SECTION.LABEL && file) {
        if (existing && existing.cp_afile_id) {
          const oldAttachment = await model.tbl_attachments.findOne({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });

          if (oldAttachment?.afile_cldId) {
            await cloudinaryManager.deleteSingleImage(
              oldAttachment.afile_cldId
            );
          }

          await model.tbl_attachments.destroy({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });
        }
        const uploadResult = await cloudinaryManager.cloudinary.uploader.upload(
          file.path
        );
        const attachment = await model.tbl_attachments.create({
          afile_type: cms_section_page_type,
          afile_record_id: cp_section_id,
          afile_path: uploadResult.secure_url,
          afile_cldId: uploadResult.public_id,
          afile_name: file.originalname
        }, { transaction });
        item.cp_afile_id = attachment.afile_id;
        fs.unlinkSync(file.path);
      }
      if (existing) {
        await existing.update(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "updated"
        });
      } else {
        await model.tbl_cms_pages.create(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "created"
        });
      }
    }
    await transaction.commit();
    return common.response(req, res, 200, true, "Home CMS updated successfully", results);
  } catch (error) {
    await transaction.rollback();
    return common.response(req, res, 422, false, error.message);
  }
};
const parseJsonArray = (data) => {
  if (!data) return [];

  let parsed = data;

  if (typeof parsed === "string") {
    try {
      parsed = JSON.parse(parsed);
    } catch {
      return [];
    }
  }

  if (!Array.isArray(parsed)) return [];

  return parsed.map(id => Number(id));
};
const getHomePageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);
    if (!cp_page_id || isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }
    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });
    const response = {
      featureTitle: "",
      featureDesc: "",
      selectedProperties: [],

      labelTitle: "",
      labelDesc: "",
      image: null,
      buttonTitle: "",
      buttonUrl: "",
      buttonTarget: "_self",

      testimonialTitle: "",
      testimonialDesc: "",
      selectedTestimonials: []
    };
    for (const item of records) {
      const sectionId = item.cp_section_id;
      if (sectionId === SECTION.FEATURE) {
        response.featureTitle = item.cp_title || "";
        response.featureDesc = item.cp_description || "";
        const ids = parseJsonArray(item.cp_hm_props);
        if (ids.length) {
          const properties = await model.tbl_properties.findAll({
            raw: true,
            where: {
              property_id: ids,
              is_active: commonConfig.isYes,
              is_deleted: commonConfig.isNo,
              is_verify: commonConfig.isYes
            },
            attributes: ["property_id", "property_name"]
          });
          response.selectedProperties = properties.map(p => ({
            id: p.property_id,
            name: p.property_name
          }));
        }
      }
      if (sectionId === SECTION.LABEL) {
        response.labelTitle = item.cp_title || "";
        response.labelDesc = item.cp_description || "";
        response.buttonTitle = item.cp_bt_title || "";
        response.buttonUrl = item.cp_btn_url || "";
        response.buttonTarget = item.cp_btn_opn || "_self";
        if (item.cp_afile_id) {
          const attachment = await model.tbl_attachments.findOne({
            where: { afile_id: item.cp_afile_id },
            raw: true
          });
          if (attachment?.afile_cldId) {
            response.image = await cloudinaryManager.getOptimizedUrl(
              attachment.afile_cldId
            );
          }
        }
      }
      if (sectionId === SECTION.TESTIMONIAL) {
        response.testimonialTitle = item.cp_title || "";
        response.testimonialDesc = item.cp_description || "";
        const ids = parseJsonArray(item.cp_hm_testimonial);
        if (ids.length) {
          const testimonials = await model.tbl_reviews.findAll({
            raw: true,
            where: { br_id: ids },
            attributes: ["br_id", "br_title"]
          });
          response.selectedTestimonials = testimonials.map(t => ({
            id: t.br_id,
            name: t.br_title
          }));
        }
      }
    }
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
    })
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
        cp_page_id, cp_section_id
      },
      attributes: ["cp_afile_id"]
    });
    console.log(findRecord, "  findRecordfindRecord")
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
    return common.response(req, res, 200, true, "Image deleted successfully");

  } catch (error) {
    return common.response(req, res, 500, false, "Failed to delete old image from Cloudinary");
  }
};

//FAQ HOMEPAGE ----------------->
const addUpdateFAQPageCMS = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const { cp_page_id } = req.body;
    const file = req.file;
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
    const results = [];
    for (const item of sections) {
      const { cp_page_id, cp_section_id } = item;
      const existing = await model.tbl_cms_pages.findOne({
        where: { cp_page_id, cp_section_id },
        transaction
      });
      if (cp_section_id === SECTION.FAQPageLabelSection && file) {
        if (existing && existing.cp_afile_id) {
          const oldAttachment = await model.tbl_attachments.findOne({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });
          if (oldAttachment?.afile_cldId) {
            await cloudinaryManager.deleteSingleImage(
              oldAttachment.afile_cldId
            );
          }
          await model.tbl_attachments.destroy({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });
        }
        const uploadResult =
          await cloudinaryManager.cloudinary.uploader.upload(file.path);
        const attachment = await model.tbl_attachments.create(
          {
            afile_type: cms_section_page_type,
            afile_record_id: cp_section_id,
            afile_path: uploadResult.secure_url,
            afile_cldId: uploadResult.public_id,
            afile_name: file.originalname
          },
          { transaction }
        );
        item.cp_afile_id = attachment.afile_id;
        fs.unlinkSync(file.path);
      }
      if (existing) {
        await existing.update(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "updated"
        });
      } else {
        await model.tbl_cms_pages.create(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "created"
        });
      }
    }
    await transaction.commit();
    return common.response(req, res, commonConfig.successStatus, true, "FAQ CMS updated successfully", results);
  } catch (error) {
    await transaction.rollback();
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};
const getFAQPageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);

    if (!cp_page_id || isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }

    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });
    const response = {
      headerTitle: "",
      headerDesc: "",
      contactTitle: "",
      contactDesc: "",
      contactBtnTitle: "",
      contactBtnUrl: "",
      contactTarget: "_self",
      labelTitle: "",
      labelDesc: "",
      labelBtnTitle: "",
      labelBtnUrl: "",
      labelTarget: "_self",
      labelImage: null
    };
    for (const item of records) {
      const sectionId = item.cp_section_id;

      if (sectionId === SECTION.FAQPageHeaderSection) {
        response.headerTitle = item.cp_title || "";
        response.headerDesc = item.cp_description || "";
      }

      if (sectionId === SECTION.FAQPageContactSection) {
        response.contactTitle = item.cp_title || "";
        response.contactDesc = item.cp_description || "";
        response.contactBtnTitle = item.cp_bt_title || "";
        response.contactBtnUrl = item.cp_btn_url || "";
        response.contactTarget = item.cp_btn_opn || "_self";
      }
      if (sectionId === SECTION.FAQPageLabelSection) {
        response.labelTitle = item.cp_title || "";
        response.labelDesc = item.cp_description || "";
        response.labelBtnTitle = item.cp_bt_title || "";
        response.labelBtnUrl = item.cp_btn_url || "";
        response.labelTarget = item.cp_btn_opn || "_self";
        if (item.cp_afile_id) {
          const attachment = await model.tbl_attachments.findOne({
            where: { afile_id: item.cp_afile_id },
            raw: true
          });

          if (attachment?.afile_cldId) {
            response.labelImage = await cloudinaryManager.getOptimizedUrl(
              attachment.afile_cldId
            );
          }
        }
      }
    }

    return common.response(req, res, commonConfig.successStatus, true, "FAQ CMS fetched successfully", response);
  } catch (error) {
    return common.response(req, res, commonConfig.errorStatus, false, error.message);
  }
};

//TC PAGE ----------------->
const addUpdateTCPageCMS = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const { cp_page_id } = req.body;
    const file = req.file;
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
    const results = [];
    for (const item of sections) {
      const { cp_page_id, cp_section_id } = item;
      const existing = await model.tbl_cms_pages.findOne({
        where: { cp_page_id, cp_section_id },
        transaction
      });
      if (cp_section_id === SECTION.TCPageLabelSection && file) {
        if (existing && existing.cp_afile_id) {
          const oldAttachment = await model.tbl_attachments.findOne({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });
          if (oldAttachment?.afile_cldId) {
            await cloudinaryManager.deleteSingleImage(
              oldAttachment.afile_cldId
            );
          }
          await model.tbl_attachments.destroy({
            where: { afile_id: existing.cp_afile_id },
            transaction
          });
        }
        const uploadResult =
          await cloudinaryManager.cloudinary.uploader.upload(file.path);
        const attachment = await model.tbl_attachments.create(
          {
            afile_type: cms_section_page_type,
            afile_record_id: cp_section_id,
            afile_path: uploadResult.secure_url,
            afile_cldId: uploadResult.public_id,
            afile_name: file.originalname
          },
          { transaction }
        );
        item.cp_afile_id = attachment.afile_id;
        fs.unlinkSync(file.path);
      }
      if (existing) {
        await existing.update(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "updated"
        });
      } else {
        await model.tbl_cms_pages.create(item, { transaction });
        results.push({
          section: cp_section_id,
          action: "created"
        });
      }
    }
    await transaction.commit();
    return common.response(req, res, 200, true, "TC CMS updated successfully", results);
  } catch (error) {
    await transaction.rollback();
    return common.response(req, res, 422, false, error.message);
  }
};
const getTCPageCMS = async (req, res) => {
  try {
    const cp_page_id = Number(req.query.cp_page_id);
    if (!cp_page_id || isNaN(cp_page_id)) {
      return common.response(req, res, 400, false, "Invalid cp_page_id");
    }
    const records = await model.tbl_cms_pages.findAll({
      where: { cp_page_id },
      raw: true
    });
    const response = {
      headerTitle: "",
      headerDesc: "",

      labelTitle: "",
      labelDesc: "",
      labelImage: null
    };
    for (const item of records) {
      const sectionId = item.cp_section_id;
      if (sectionId === SECTION.TCHeaderSection) {
        response.headerTitle = item.cp_title || "";
        response.headerDesc = item.cp_description || "";
      }
      if (sectionId === SECTION.TCPageLabelSection) {
        response.labelTitle = item.cp_title || "";
        response.labelDesc = item.cp_description || "";

        if (item.cp_afile_id) {
          const attachment = await model.tbl_attachments.findOne({
            where: { afile_id: item.cp_afile_id },
            raw: true
          });
          if (attachment?.afile_cldId) {
            response.labelImage = await cloudinaryManager.getOptimizedUrl(
              attachment.afile_cldId
            );
          }
        }
      }
    }
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