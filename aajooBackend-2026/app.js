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
const { validateFirebaseCredentials } = require("./utils/methods");
const { startScheduler } = require('./utils/campaignScheduler');

const port = process.env.PORT || 8080;

const app = express();
process.env.TZ = "Asia/Calcutta";
// const allowedOrigin = process.env.FRONTEND_URL || "http://localhost:5173";

const getDatabaseConnectionSummary = () => {
  const dbConfig = sequelize?.config || {};
  const host = dbConfig.host || "unknown-host";
  const database = dbConfig.database || "unknown-database";
  const dbPort = dbConfig.port || "default";
  const isLocalHost = ["127.0.0.1", "localhost", "::1"].includes(host);

  return {
    type: isLocalHost ? "local" : "remote",
    host,
    port: dbPort,
    database,
  };
};

app.set('trust proxy', 1);
// Capture the raw request body buffer for webhook HMAC verification (Didit KYC,
// A-12). The `verify` callback runs during JSON parsing and stashes the
// unparsed bytes on req.rawBody — used by controllers/verify.controller.js
// webhook handler. Standard Stripe/Brevo pattern; zero impact on normal routes.
app.use(express.json({
  verify: (req, res, buf) => {
    req.rawBody = buf;
  },
}));
// app.options("*", cors());
// app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("uploads"));
app.use(
  cors({
    origin: true ,// Allow all origins for now (consider restricting in production)
    // credentials: true,
    allowedHeaders: ["Content-Type", "Authorization"],
    methods: ["GET", "POST", "DELETE", "OPTIONS"],
    optionsSuccessStatus: 204,
    maxAge: 10800,
  })
);

const getRequestLogBody = (req) => {
  const body = req.body;
  if (!body || Array.isArray(body)) {
    return body;
  }

  if (req.originalUrl.startsWith("/admin")) {
    return {
      redacted: true,
      keys: Object.keys(body),
    };
  }

  const sensitiveKeys = new Set([
    "password",
    "confirmPassword",
    "cred_user_password",
    "authorization",
    "token",
    "accessToken",
    "refreshToken",
  ]);

  return Object.fromEntries(
    Object.entries(body).map(([key, value]) => [
      key,
      sensitiveKeys.has(key) ? "[REDACTED]" : value,
    ])
  );
};

app.use((req, res, next) => {
  const start = process.hrtime();

  res.on('finish', () => {
    const [sec, nanosec] = process.hrtime(start);
    const durationMs = (sec * 1e3 + nanosec / 1e6).toFixed(2);

    logger.info('HTTP Request', {
      method: req.method,
      path: req.originalUrl,
      // body: getRequestLogBody(req),
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

// Lightweight health endpoint for uptime monitors / keep-alive pingers
// (e.g. cron-job.org, UptimeRobot, BetterStack). Intentionally:
//   - no rate limiter (so a pinger every 5–10 min isn't throttled)
//   - no DB call (won't fail when the DB is briefly unreachable)
//   - returns a small JSON payload so monitors can check body, not just 2xx
// See KEEP_ALIVE_SETUP.md for the recommended monitor config.
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: "aajao-backend",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});
app.head("/health", (req, res) => res.sendStatus(200));

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

app.get('/privacy-policy', generalLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});
app.get('/account-deletion-policy', generalLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'account-deletion-policy.html'));
});

const httpServer = http.createServer(app);
httpServer.on('error', (error) => {
  logger.error('HTTP server failed to start.', {
    code: error?.code || null,
    message: error?.message || null,
    stack: error?.stack || null,
  });
  console.error('HTTP server failed to start:', error);
});

process.on('exit', (code) => {
  logger.info(`Process exiting with code ${code}`);
  console.log(`Process exiting with code ${code}`);
});

process.on('SIGTERM', () => {
  logger.warn('SIGTERM received by app process.');
  console.warn('SIGTERM received by app process.');
});

process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception in app process.', {
    message: error?.message || null,
    stack: error?.stack || null,
  });
  console.error('Uncaught exception in app process:', error);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled promise rejection in app process.', {
    reason: reason instanceof Error ? reason.message : reason,
    stack: reason instanceof Error ? reason.stack : null,
  });
  console.error('Unhandled promise rejection in app process:', reason);
});
// Initialize Socket.io
const io = new Server(httpServer, {
  cors: {
    origin: "*", // Allow all origins for now (consider restricting in production)
    methods: ["GET", "POST"],
  },
});

app.locals.io = io;

setupSocketHandlers(io);

(async () => {
  // [DEV] Boot-time DB authenticate is non-fatal — the server starts even if
  // the DB is briefly unreachable (connects lazily on first query). This
  // matches the prior local behavior and keeps UI/dev testing unblocked.
  try {
    await sequelize.authenticate();
    const dbSummary = getDatabaseConnectionSummary();
    logger.info("✅ Database connection established successfully.");
    logger.info("Database connection summary", dbSummary);
  } catch (error) {
    console.error("⚠️ DB authenticate at boot failed (continuing anyway):", error.message);
  }

  // [DEV] Don't let a scheduler failure crash boot.
  try {
    await startScheduler();
  } catch (error) {
    console.error("⚠️ Scheduler failed to start (continuing):", error.message);
  }

  httpServer.listen(port, '0.0.0.0', () => {
    logger.info(`🚀 Server running on http://localhost:${port}`);
  });
})();


