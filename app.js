const express = require("express");
const path = require("path");

const app = express();

// Read configuration from environment variables (injected via ConfigMap and Secret)
const APP_NAME = process.env.APP_NAME || "EKS Node.js WebApp";
const APP_VERSION = process.env.APP_VERSION || "1.0.0";
const APP_ENV = process.env.APP_ENV || "development";
const API_KEY = process.env.API_KEY || "not-configured";

// Track application start time for uptime calculations
const startTime = Date.now();

// Basic middleware
app.use(express.json());

// Helper: format uptime in seconds (float)
function getUptimeSeconds() {
  return Math.round(process.uptime());
}

// Helper: render a simple HTML dashboard
function renderDashboard() {
  const uptimeSeconds = getUptimeSeconds();
  return `
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>${APP_NAME} – Dashboard</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style>
          body {
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            margin: 0;
            padding: 0;
            background: radial-gradient(circle at top, #1e293b, #020617);
            color: #e5e7eb;
          }
          .wrapper {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .card {
            background: rgba(15, 23, 42, 0.9);
            border-radius: 16px;
            padding: 32px 40px;
            box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.9);
            max-width: 640px;
            width: 100%;
            border: 1px solid rgba(148, 163, 184, 0.3);
          }
          .title {
            font-size: 1.75rem;
            font-weight: 700;
            margin-bottom: 4px;
          }
          .subtitle {
            color: #9ca3af;
            margin-bottom: 24px;
            font-size: 0.95rem;
          }
          .badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 9999px;
            font-size: 0.75rem;
            background: rgba(56, 189, 248, 0.1);
            color: #e0f2fe;
            margin-right: 8px;
          }
          .badge.env {
            background: rgba(74, 222, 128, 0.1);
            color: #dcfce7;
          }
          .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-top: 24px;
          }
          .metric {
            padding: 12px 14px;
            border-radius: 12px;
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid rgba(148, 163, 184, 0.4);
          }
          .metric-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: #9ca3af;
            margin-bottom: 4px;
          }
          .metric-value {
            font-size: 1.1rem;
            font-weight: 600;
          }
          .footer {
            margin-top: 24px;
            font-size: 0.8rem;
            color: #6b7280;
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 8px;
          }
          .links a {
            color: #38bdf8;
            text-decoration: none;
            margin-right: 12px;
          }
          .links a:hover {
            text-decoration: underline;
          }
          @media (max-width: 640px) {
            .card {
              border-radius: 0;
              min-height: 100vh;
              box-shadow: none;
            }
          }
        </style>
      </head>
      <body>
        <div class="wrapper">
          <div class="card">
            <div>
              <div class="badge">Node.js + Express</div>
              <div class="badge env">Environment: ${APP_ENV}</div>
            </div>
            <h1 class="title">${APP_NAME}</h1>
            <div class="subtitle">
              Version ${APP_VERSION} • Uptime: ${uptimeSeconds} seconds • Deployed on Amazon EKS
            </div>

            <div class="grid">
              <div class="metric">
                <div class="metric-label">App Name</div>
                <div class="metric-value">${APP_NAME}</div>
              </div>
              <div class="metric">
                <div class="metric-label">Version</div>
                <div class="metric-value">${APP_VERSION}</div>
              </div>
              <div class="metric">
                <div class="metric-label">Environment</div>
                <div class="metric-value">${APP_ENV}</div>
              </div>
              <div class="metric">
                <div class="metric-label">Uptime (s)</div>
                <div class="metric-value">${uptimeSeconds}</div>
              </div>
              <div class="metric">
                <div class="metric-label">API Key Configured</div>
                <div class="metric-value">
                  ${API_KEY && API_KEY !== "not-configured" ? "Yes" : "No"}
                </div>
              </div>
              <div class="metric">
                <div class="metric-label">Started At</div>
                <div class="metric-value">
                  ${new Date(startTime).toISOString()}
                </div>
              </div>
            </div>

            <div class="footer">
              <div class="links">
                <a href="/health">/health</a>
                <a href="/api/info">/api/info</a>
              </div>
              <div>Pod IP: rendered by container • Cluster: Amazon EKS</div>
            </div>
          </div>
        </div>
      </body>
    </html>
  `;
}

// GET / 4 HTML dashboard
app.get("/", (req, res) => {
  res.set("Content-Type", "text/html; charset=utf-8");
  res.send(renderDashboard());
});

// GET /health b simple health check for liveness/readiness probes
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    uptime: getUptimeSeconds(),
    timestamp: new Date().toISOString(),
  });
});

// GET /api/info b structured app metadata
app.get("/api/info", (req, res) => {
  res.json({
    appName: APP_NAME,
    version: APP_VERSION,
    environment: APP_ENV,
    uptimeSeconds: getUptimeSeconds(),
    apiKeyConfigured: !!API_KEY && API_KEY !== "not-configured",
    startedAt: new Date(startTime).toISOString(),
  });
});

// Fallback 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not Found",
    path: req.originalUrl,
  });
});

// Global error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({
    error: "Internal Server Error",
  });
});

// Start server
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(
    `${APP_NAME} v${APP_VERSION} running in ${APP_ENV} on port ${PORT}`
  );
  console.log(`Started at: ${new Date(startTime).toISOString()}`);
});
