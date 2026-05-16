#!/bin/bash
set -ex

# ─── System Update ───────────────────────────────────────
yum update -y
yum install -y nginx curl wget git htop

# ─── System Info Variables ───────────────────────────────
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
HOSTNAME=$(hostname)
LAUNCHED_AT=$(date '+%Y-%m-%d %H:%M:%S UTC')

# ─── Custom HTML Page ─────────────────────────────────────
cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>My EC2 Server</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 40px;
      max-width: 600px;
      width: 90%;
      box-shadow: 0 25px 50px rgba(0,0,0,0.5);
    }
    .badge {
      background: #22c55e22;
      color: #22c55e;
      border: 1px solid #22c55e55;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 13px;
      display: inline-block;
      margin-bottom: 16px;
    }
    h1 { font-size: 28px; margin-bottom: 8px; color: #f8fafc; }
    .subtitle { color: #94a3b8; margin-bottom: 32px; font-size: 15px; }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    .info-box {
      background: #0f172a;
      border: 1px solid #334155;
      border-radius: 10px;
      padding: 14px 16px;
    }
    .info-box .label {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: #64748b;
      margin-bottom: 4px;
    }
    .info-box .value {
      font-size: 14px;
      color: #38bdf8;
      font-weight: 500;
      word-break: break-all;
    }
    .footer {
      margin-top: 28px;
      text-align: center;
      font-size: 13px;
      color: #475569;
    }
    .footer span { color: #f97316; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">● Live</div>
    <h1>Hello from EC2! 🚀</h1>
    <p class="subtitle">Deployed with Terraform + UserData</p>
    <div class="grid">
      <div class="info-box">
        <div class="label">Instance ID</div>
        <div class="value">$INSTANCE_ID</div>
      </div>
      <div class="info-box">
        <div class="label">Public IP</div>
        <div class="value">$PUBLIC_IP</div>
      </div>
      <div class="info-box">
        <div class="label">Region</div>
        <div class="value">$REGION</div>
      </div>
      <div class="info-box">
        <div class="label">Availability Zone</div>
        <div class="value">$AZ</div>
      </div>
      <div class="info-box">
        <div class="label">Instance Type</div>
        <div class="value">$INSTANCE_TYPE</div>
      </div>
      <div class="info-box">
        <div class="label">Hostname</div>
        <div class="value">$HOSTNAME</div>
      </div>
    </div>
    <div class="footer">Launched at <span>$LAUNCHED_AT</span></div>
  </div>
</body>
</html>
HTML

# ─── Nginx Config ─────────────────────────────────────────
systemctl enable nginx
systemctl start nginx

echo "✅ UserData complete!"
