const yup = require("yup");

exports.createBlog = yup.object({
    blog_title: yup
        .string()
        .required("title is required"),
    blog_short_desc: yup
        .string()
        .required("short decription is required"),
    blog_long_desc: yup
        .string(),
    blog_writerId: yup
        .number()
});