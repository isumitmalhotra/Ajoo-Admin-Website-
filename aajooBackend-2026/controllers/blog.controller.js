const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const moduleConfig = require("../config/moduleConfigs");

const createBlog = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let blogId = reqData.blogId;
        const payload = {
            blog_title: reqData.blog_title,
            blog_short_desc: reqData.blog_short_desc,
            blog_long_desc: reqData.blog_long_desc,
            blog_writerId: reqData.blog_writerId ?? 1,
        };
        if (blogId) {
            await model.tbl_blog.blogUpdate(blogId, payload);
        } else {
            const data = await model.tbl_blog.blogCreate(payload);
            blogId = data.blog_id;
        }
        if (req.file) {
            await model.tbl_attachments.handleSingle(req.file, blogId, moduleConfig.blog_image_type);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success");
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const blogs = async (req, res) => {
    try {
        const reqData = { ...req.body };
        let whereClause = {
            blog_isActive: commonConfig.isYes,
            blog_isDelete: commonConfig.isNo,
        };
        const data = await model.tbl_blog.getBlogs(whereClause, moduleConfig.blog_image_type);
        if (data.length == 0) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found");
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", data);
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

const testImage = async (req, res) => { 
    const { CloudinaryManager } = require("../utils/cloudinary")
    try {
        const cloudinaryInstance = new CloudinaryManager();
        const filePath = req.file.path;
        // const uploadResult = await cloudinaryInstance.uploadImage(filePath, 1, 1);
        // const image = await cloudinaryInstance.getOptimizedUrl("tw7yzffvvyedpxxzscfg");
        // console.log(image)
        console.log(req.file);
    } catch (error) {
        console.log(error)
    }
}
module.exports = {
    createBlog,
    blogs,
    testImage
}
