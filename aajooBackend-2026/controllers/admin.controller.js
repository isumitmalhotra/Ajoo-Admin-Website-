const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const methods = require("../utils/methods");
const { Op, fn, col, literal } = require('sequelize');
const { use } = require("passport");
// const moduleConfig = require("../config/moduleConfigs");

const normalizeAdminString = (value) => {
    if (typeof value !== "string") {
        return null;
    }

    const trimmedValue = value.trim();
    return trimmedValue ? trimmedValue : null;
};

const createAdmin = async (req, res) => {
    try {
        const adminCount = await model.tbl_admins.count();

        if (adminCount > 0 && !req.admin) {
            return common.response(req, res, 401, false, "Authorization token is required");
        }

        if (adminCount > 0 && Number(req.admin?.isAdmin) !== commonConfig.isYes) {
            return common.response(req, res, 403, false, "Only super admins can create admin accounts");
        }

        const adminName = normalizeAdminString(req.body.admin_name);
        const adminEmail = normalizeAdminString(req.body.admin_email)?.toLowerCase();
        const requestedUsername = normalizeAdminString(req.body.admin_username);
        const adminUsername = requestedUsername || adminEmail?.split("@")[0] || adminName;

        const [existingEmailAdmin, existingUsernameAdmin] = await Promise.all([
            model.tbl_admins.findOne({
                raw: true,
                where: {
                    admin_email: adminEmail,
                },
            }),
            model.tbl_admins.findOne({
                raw: true,
                where: {
                    admin_username: adminUsername,
                },
            }),
        ]);

        if (existingEmailAdmin) {
            return common.response(req, res, commonConfig.conflictStatus, false, "Admin email already exists");
        }

        if (existingUsernameAdmin) {
            return common.response(req, res, commonConfig.conflictStatus, false, "Admin username already exists");
        }

        const hashedPassword = await methods.hashPassword(req.body.admin_password);

        const createdAdmin = await model.tbl_admins.create({
            admin_name: adminName,
            admin_username: adminUsername,
            admin_email: adminEmail,
            admin_password: hashedPassword,
            admin_isAdmin: req.body.admin_isAdmin ?? commonConfig.isYes,
            admin_isActive: req.body.admin_isActive ?? commonConfig.isYes,
        });

        const safeAdmin = createdAdmin.get({ plain: true });
        delete safeAdmin.admin_password;

        return common.response(
            req,
            res,
            commonConfig.createdStatus,
            true,
            "Admin created successfully",
            safeAdmin
        );
    } catch (error) {
        return common.response(req, res, commonConfig.serverErrorStatus, false, error.message);
    }
};


const adminLogin = async (req, res) => {
    try {
        const { username, password } = req.body;
        const admin = await model.tbl_admins.findAdmin({ admin_email: username, });
        if (!admin || admin == null) {
            await model.tbl_admin_login_logs.create({
                ip_address: req.ip,
                user_agent: req.headers["user-agent"],
                is_success: false,
            });
            return common.response(req, res, commonConfig.errorStatus, false, "Invalid credentials");
        }
        const isMatch = await methods.verifyPassword(password, admin.admin_password);
        if (!isMatch) {
            await model.tbl_admin_login_logs.create({
                admin_id: admin.admin_id,
                role_id: admin.role_id || null,
                ip_address: req.ip,
                user_agent: req.headers["user-agent"],
                is_success: false,
            });
            return common.response(req, res, commonConfig.errorStatus, false, "Invalid credentials");
        }

        const token = await methods.genrateToken({
            adminId: admin.admin_id,
            isAdmin: admin.admin_isAdmin,
        });

        await model.tbl_admin_login_logs.create({
            admin_id: admin.admin_id,
            role_id: admin.role_id || null,
            ip_address: req.ip,
            user_agent: req.headers["user-agent"],
            is_success: true,
        });

        const { admin_password, ...safeAdmin } = admin;
        return common.response(req, res, commonConfig.successStatus, true, "Login successful", { admin: { ...safeAdmin, token, } }
        );
    } catch (error) {
        console.error("Admin login error:", error);
        try {
            await model.tbl_admin_login_logs.create({
                admin_id: null,
                ip_address: req.ip,
                user_agent: req.headers["user-agent"],
                is_success: false,
            });
        } catch (e) {
            console.error("Failed to log admin login attempt:", e);
        }
        return common.response(req, res, commonConfig.errorStatus, false, "Something went wrong. Please try again.");
    }
};
const adminLogout = async (req, res) => {
    try {
        const adminId = req.admin?.adminId; // set by auth middleware
        const token = req.token; // extracted token
        if (adminId) {
            await model.tbl_admin_login_logs.create({
                admin_id: adminId,
                role_id: null,
                ip_address: req.ip,
                user_agent: req.headers["user-agent"],
                login_at: new Date(),
                is_success: true,
                // action: "LOGOUT"
            });
        }
        return common.response(req, res, commonConfig.successStatus, true, "Logout successful");
    } catch (error) {
        console.error("Admin logout error:", error);
        return common.response(req, res, commonConfig.errorStatus, false, "Something went wrong. Please try again.");
    }
};
// const addCreate = async (req, res) => {
//     try {
//         const password = await methods.hashPassword(req.body.password);
//         return common.response(req, res, commonConfig.successStatus, true, "success", password);
//     } catch (error) {
//         return common.response(req, res, commonConfig.errorStatus, false, error.message);
//     }
// };

const SUCCESS_STATUS = 13;
const CANCELLED_STATUS = 2;


const getMonthlyBookings = async () => {
    try {
        const year = new Date().getFullYear();
        const bookings = await model.tbl_bookings.findAll({
            attributes: [
                [fn('MONTH', col('book_added_at')), 'month'],
                'book_status',
                [fn('COUNT', col('book_pri_id')), 'count'],
            ],
            where: {
                book_is_delete: commonConfig.isNo,
                book_status: { [Op.in]: [SUCCESS_STATUS, CANCELLED_STATUS] },
                book_added_at: {
                    [Op.gte]: new Date(`${year}-01-01`),
                    [Op.lte]: new Date(`${year}-12-31`),
                },
            },
            group: ['month', 'book_status'],
            raw: true,
        });

        const monthlyData = Array.from({ length: 12 }, (_, i) => ({
            month: i + 1,
            successful: 0,
            cancelled: 0,
        }));

        bookings.forEach((b) => {
            const monthIndex = b.month - 1;
            if (parseInt(b.book_status) === SUCCESS_STATUS) {
                monthlyData[monthIndex].successful += parseInt(b.count);
            } else if (parseInt(b.book_status) === CANCELLED_STATUS) {
                monthlyData[monthIndex].cancelled += parseInt(b.count);
            }
        });

        const response = {
            months: [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ],
            successful: monthlyData.map((m) => m.successful),
            cancelled: monthlyData.map((m) => m.cancelled),
        };
        return response;
    } catch (error) {
        throw error;
    }
};
const getLastNDays = (n = 10) => {
    const days = [];
    for (let i = n - 1; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const formatted = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        days.push(formatted);
    }
    return days;
};
const getDailyUsers = async () => {
    try {
      const DAYS = 10; // past 10 days
      const today = new Date();
      const startDate = new Date();
      startDate.setDate(today.getDate() - (DAYS - 1)); // 10 days ago
  
      const users = await model.tbl_user.findAll({
        attributes: [
          [fn("DATE", col("added_at")), "date"],
          [fn("COUNT", col("user_id")), "count"],
        ],
        where: {
          user_isDelete: commonConfig.isNo,
          user_isUser: commonConfig.isYes,
          added_at: {
            [Op.gte]: startDate,
            [Op.lte]: today,
          },
        },
        group: [literal("DATE(added_at)")],
        raw: true,
      });
  
      // Helper to format date => Feb 12
      const formatDate = (dateStr) => {
        const date = new Date(dateStr);
        return date.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        });
      };
  
      // Get last N days in YYYY-MM-DD
      const lastNDays = getLastNDays(DAYS);
  
      // Prepare user count data
      const userData = lastNDays.map((d) => {
        const userRecord = users.find((u) => u.date === d);
        return userRecord ? parseInt(userRecord.count) : 0;
      });
  
      // Format dates for frontend (Feb 12, Feb 13, ...)
      const formattedDates = lastNDays.map(formatDate);
  
      const data = {
        dates: formattedDates,  
        users: userData,
      };
  
      return data;
    } catch (error) {
      throw error;
    }
  };
// const getDailyUsers = async (req, res) => {
//     try {
//         const DAYS = 10; // past 10 days
//         const today = new Date();
//         const startDate = new Date();
//         startDate.setDate(today.getDate() - (DAYS - 1)); // 10 days ago
//         const users = await model.tbl_user.findAll({
//             attributes: [
//                 [fn('DATE', col('added_at')), 'date'],
//                 [fn('COUNT', col('user_id')), 'count'],
//             ],
//             where: {
//                 user_isDelete: commonConfig.isNo,
//                 user_isUser: commonConfig.isYes,
//                 added_at: {
//                     [Op.gte]: startDate,
//                     [Op.lte]: today,
//                 },
//             },
//             group: [literal('DATE(added_at)')],
//             raw: true,
//         });

//         // Prepare response array with 0 defaults
//         const lastNDays = getLastNDays(DAYS);
//         const userData = lastNDays.map((d) => {
//             const userRecord = users.find(u => u.date === d);
//             return userRecord ? parseInt(userRecord.count) : Math.floor(Math.random() * 10) + 5; // add dummy if 0
//         });
//         const data = {
//             dates: lastNDays,
//             users: userData,
//         }
//         return data;

//     } catch (error) {
//         return error;
//     }
// };
const getUserStats = async () => {
    try {
        const totalUsers = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isUser: commonConfig.isYes,
            },
        });

        const active = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isUser: commonConfig.isYes,
                user_isActive: commonConfig.isYes,
            },
        });

        const inactive = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isUser: commonConfig.isYes,
                user_isActive: commonConfig.isNo,
            },
        });

        const verified = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isUser: commonConfig.isYes,
                user_isVerified: commonConfig.isYes,
            },
        });

        const other = totalUsers - (active + inactive + verified);
        return { active, inactive, verified, other };

    } catch (error) {
        throw error;
    }
};
const getHostStats = async () => {
    try {
        const totalHosts = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isHost: commonConfig.isYes,
            },
        });

        const active = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isHost: commonConfig.isYes,
                user_isActive: commonConfig.isYes,
            },
        });
        const inactive = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isHost: commonConfig.isYes,
                user_isActive: commonConfig.isNo,
            },
        });
        const verified = await model.tbl_user.count({
            where: {
                user_isDelete: commonConfig.isNo,
                user_isHost: commonConfig.isYes,
                user_isVerified: commonConfig.isYes,
            },
        });
        const other = totalHosts - (active + inactive + verified);
        return { active, inactive, verified, other };
    } catch (error) {
        throw error;
    }
};
const getPropStats = async () => {
    try {
        const totalproperty = await model.tbl_properties.count({
            where: {
                is_deleted: commonConfig.isNo,
            },
        });

        const active = await model.tbl_properties.count({
            where: {
                is_deleted: commonConfig.isNo,
                is_active: commonConfig.isYes,
            },
        });
        const inactive = await model.tbl_properties.count({
            where: {
                is_deleted: commonConfig.isNo,
                is_active: commonConfig.isNo,
            },
        });
        const verified = await model.tbl_properties.count({
            where: {
                is_deleted: commonConfig.isNo,
                is_verify: commonConfig.isYes,
            },
        });
        const other = totalproperty - (active + inactive + verified);
        return { active, inactive, verified, other };
    } catch (error) {
        throw error;
    }
};

const adminDashboard = async (req, res) => {
    try {
        const [
            getMonthlyBookingsData,
            getDailyUsersData,
            getUserStatsData,
            getHostStatsData,
            getPropStatsData,
            userCount,
            hostCount,
            propCount,
            BookingCount,
            pendingPropCount,
            getLatestUser,
            getLatestBooking,
            getLatestProperties,
        ] = await Promise.all([
            getMonthlyBookings(),
            getDailyUsers(),
            getUserStats(),
            getHostStats(),
            getPropStats(),
            model.tbl_user.count({
                where: {
                    user_isDelete: commonConfig.isNo,
                    user_isUser: commonConfig.isYes,
                    user_isActive: commonConfig.isYes,
                }
            }),
            model.tbl_user.count({
                where: {
                    user_isDelete: commonConfig.isNo,
                    user_isHost: commonConfig.isYes,
                    user_isActive: commonConfig.isYes,
                }
            }),
            model.tbl_properties.count({
                where: {
                    is_deleted: commonConfig.isNo,
                    is_verify: commonConfig.isYes,
                    is_active: commonConfig.isYes,
                }
            }),
            model.tbl_bookings.count({
                where: {
                    book_is_delete: commonConfig.isNo,
                    book_status: { [Op.ne]: 2 }
                }
            }),
            model.tbl_properties.count({
                where: {
                    is_deleted: commonConfig.isNo,
                    is_verify: commonConfig.isNo,
                }
            }),
            model.tbl_user.findAll({
                raw: true,
                where: {
                    user_isDelete: commonConfig.isNo,
                    user_isUser: commonConfig.isYes,
                },
                include: {
                    model: model.tbl_user_cred,
                    as: "userCred",
                    required: true,
                    attributes: ["cred_user_email"]
                },
                order: [['added_at', 'DESC']],
                attributes: ["user_fullName", "user_isVerified", "user_isActive"],
                limit: 5
            }),
            model.tbl_bookings.findAll({
                raw: true,
                where: {
                    book_is_delete: commonConfig.isNo,
                },
                order: [["book_added_at", "DESC"]],
                attributes: ["book_id", "book_total_amt", "book_is_paid", "book_status"],
                include: [
                    {
                        model: model.tbl_book_status,
                        as: "bookingStatus",
                        required: true,
                        attributes: ["bs_title", "bs_code"],
                    },
                ],
                limit: 5
            }),
            model.tbl_properties.findAll({
                raw: true,
                where: {
                    is_deleted: commonConfig.isNo,
                },
                order: [["created_at", "DESC"]],
                limit: 5,
                attributes: ["property_name", "property_price", "is_verify", "is_active"]
            })
        ]);
        return common.response(req, res, commonConfig.successStatus, true, "Dashboard data fetched successfully", {
            userCount,
            hostCount,
            propCount,
            BookingCount,
            pendingPropCount,
            getMonthlyBookingsData,
            getDailyUsersData,
            getUserStatsData,
            getHostStatsData,
            getPropStatsData,
            getLatestUser,
            getLatestBooking,
            getLatestProperties
        });

    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};



// GET /admin/verify-token (INT-02) — the admin FE auth guard calls this on boot
// to confirm the stored token is still valid. adminAuth middleware validates the
// JWT first; reaching this handler means the token is valid (invalid/expired → 401).
const verifyToken = async (req, res) => {
    try {
        return common.response(req, res, commonConfig.successStatus, true, "Token valid", {
            adminId: req.admin?.adminId ?? null,
            isAdmin: req.admin?.isAdmin ?? null,
            role: req.admin?.role ?? "admin",
            isValid: true,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};

module.exports = {
    createAdmin,
    adminLogin,
    adminLogout,
    adminDashboard,
    verifyToken
}

