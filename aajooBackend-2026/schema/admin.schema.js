const yup = require("yup");

exports.adminLogin = yup.object({
    username: yup
        .string()
        .required("username is required"),
    password: yup
        .string()
        .required("password is required"),

});