const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const path = require("path");
const fs = require("fs");
const http = require("http");
const { Server } = require("socket.io");
const setupSocketHandlers = require("./sockets");
const logger = require("./utils/logger");
require("dotenv").config();
const { sequelize } = require('./models');
const { generalLimiter } = require("./middleware/rateLimiter");
const errorHandler = require("./middleware/errorHandler");

const port = process.env.PORT || 8080;

const app = express();
process.env.TZ = "Asia/Calcutta";
const allowedOrigin = process.env.FRONTEND_URL || "http://localhost:5173";

app.set('trust proxy', 1);
app.use(express.json());
// app.options("*", cors());
// app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("uploads"));
app.use(
  cors({
    origin: allowedOrigin, // <-- must be frontend URL
    // credentials: true,      // allow cookies / auth headers
    allowedHeaders: ["Content-Type", "Authorization"],
    methods: ["GET", "POST", "DELETE", "OPTIONS"],
    optionsSuccessStatus: 204,
    maxAge: 10800,
  })
);
app.use((req, res, next) => {
  const start = process.hrtime();

  res.on('finish', () => {
    const [sec, nanosec] = process.hrtime(start);
    const durationMs = (sec * 1e3 + nanosec / 1e6).toFixed(2);

    logger.info('HTTP Request', {
      method: req.method,
      path: req.originalUrl,
      body: req.body,
      statusCode: res.statusCode,
      responseTime: `${durationMs}ms`,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
      requestId: req.id || 'N/A'
    });
  });

  next();
})

app.use(
  "/uploads/admin_dashboard",
  express.static(path.join(__dirname, "uploads"))
);
// Serve static files (optional)
app.use(express.static(path.join(__dirname, 'public')));

app.get("/", generalLimiter, (req, res) => {
  res.send("Hello Backend!");
});

app.use("/api/status", generalLimiter, (req, res) => {
  res.json({ message: "API is working!" });
});
const routePath = path.resolve(__dirname) + "/routes/";
fs.readdirSync(routePath).forEach((file) => {
  try {
    const route = require(path.join(routePath, file));
    app.use(route);
  } catch (err) {
    console.error(`❌ Failed to load route ${file}:`, err.message);
  }
});

app.use(errorHandler);
app.get('/db-test', generalLimiter, async (req, res) => {
  try {
    await sequelize.authenticate();
    res.send('✅ DB connection successful!');
  } catch (error) {
    res.status(500).send('❌ DB connection failed: ' + error.message);
  }
});

process.on('uncaughtException', err => {
  console.error('🔥 Uncaught Exception:', err);
});

process.on('unhandledRejection', err => {
  console.error('🔥 Unhandled Rejection:', err);
});

app.get('/privacy-policy', generalLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});
app.get('/account-deletion-policy', generalLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'account-deletion-policy.html'));
});



const httpServer = http.createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

app.locals.io = io;

setupSocketHandlers(io);

(async () => {
  try {
    logger.info("✅ Database connection established successfully.");

    httpServer.listen(port, '0.0.0.0', () => {
      logger.info(`🚀 Server running on http://localhost:${port}`);
    });

  } catch (error) {
    console.error("❌ Unable to connect to database:", error);
    process.exit(1);
  }
})();


