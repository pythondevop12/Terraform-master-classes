#!/bin/bash
set -ex

# ─────────────────────────────────────────────
#   SYSTEM SETUP
# ─────────────────────────────────────────────
yum update -y
yum install -y nginx curl wget git htop unzip tree net-tools

# ─────────────────────────────────────────────
#   FETCH INSTANCE METADATA (IMDSv2)
# ─────────────────────────────────────────────
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
AMI_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id)
HOSTNAME=$(hostname)
OS_VERSION=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
CPU_COUNT=$(nproc)
TOTAL_RAM=$(free -h | awk '/^Mem:/{print $2}')
DISK_SIZE=$(df -h / | awk 'NR==2{print $2}')
LAUNCHED_AT=$(date '+%Y-%m-%d %H:%M:%S UTC')
UPTIME=$(uptime -p)

# ─────────────────────────────────────────────
#   CREATE WEBSITE
# ─────────────────────────────────────────────
mkdir -p /usr/share/nginx/html

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>EC2 Dashboard</title>
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: #030712;
      color: #e2e8f0;
      min-height: 100vh;
      padding: 40px 20px;
    }
    .container { max-width: 860px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 40px; }
    .live-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #052e16;
      border: 1px solid #166534;
      color: #4ade80;
      padding: 5px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.05em;
      margin-bottom: 18px;
    }
    .live-dot {
      width: 7px; height: 7px;
      background: #4ade80;
      border-radius: 50%;
      animation: pulse 1.5s ease-in-out infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50%       { opacity: 0.4; transform: scale(0.8); }
    }
    .header h1 {
      font-size: 36px;
      font-weight: 700;
      background: linear-gradient(135deg, #38bdf8, #818cf8, #f472b6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 8px;
    }
    .header p { color: #64748b; font-size: 15px; }
    .section-title {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      color: #475569;
      margin: 32px 0 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .section-title::after {
      content: '';
      flex: 1;
      height: 1px;
      background: #1e293b;
    }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
    @media(max-width: 600px) {
      .grid-2, .grid-3 { grid-template-columns: 1fr; }
    }
    .card {
      background: #0f172a;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 16px 18px;
      transition: border-color 0.2s;
    }
    .card:hover { border-color: #334155; }
    .card .label {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: #475569;
      margin-bottom: 6px;
    }
    .card .value { font-size: 14px; font-weight: 600; color: #e2e8f0; word-break: break-all; }
    .card .value.highlight { color: #38bdf8; }
    .card .value.green     { color: #4ade80; }
    .card .value.purple    { color: #a78bfa; }
    .card .value.orange    { color: #fb923c; }
    .stat-card {
      background: #0f172a;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 20px;
      text-align: center;
    }
    .stat-card .stat-icon  { font-size: 28px; margin-bottom: 8px; }
    .stat-card .stat-value { font-size: 22px; font-weight: 700; color: #f8fafc; }
    .stat-card .stat-label { font-size: 12px; color: #64748b; margin-top: 4px; }
    .terminal {
      background: #020617;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 20px;
      font-family: 'Courier New', monospace;
      font-size: 13px;
      line-height: 1.8;
    }
    .terminal .t-prompt { color: #4ade80; }
    .terminal .t-cmd    { color: #e2e8f0; }
    .footer {
      text-align: center;
      margin-top: 48px;
      padding-top: 24px;
      border-top: 1px solid #1e293b;
      color: #334155;
      font-size: 13px;
    }
    .footer span { color: #f97316; font-weight: 600; }
  </style>
</head>
<body>
<div class="container">

  <div class="header">
    <div class="live-badge"><div class="live-dot"></div> LIVE</div>
    <h1>EC2 Instance Dashboard</h1>
    <p>Deployed with Terraform + UserData &nbsp;•&nbsp; Amazon Linux 2</p>
  </div>

  <div class="section-title">🖥️ Instance Info</div>
  <div class="grid-2">
    <div class="card"><div class="label">Instance ID</div><div class="value highlight">$INSTANCE_ID</div></div>
    <div class="card"><div class="label">Instance Type</div><div class="value purple">$INSTANCE_TYPE</div></div>
    <div class="card"><div class="label">AMI ID</div><div class="value">$AMI_ID</div></div>
    <div class="card"><div class="label">Hostname</div><div class="value">$HOSTNAME</div></div>
  </div>

  <div class="section-title">🌐 Network</div>
  <div class="grid-2">
    <div class="card"><div class="label">Public IP</div><div class="value green">$PUBLIC_IP</div></div>
    <div class="card"><div class="label">Private IP</div><div class="value">$PRIVATE_IP</div></div>
    <div class="card"><div class="label">Region</div><div class="value orange">$REGION</div></div>
    <div class="card"><div class="label">Availability Zone</div><div class="value">$AZ</div></div>
  </div>

  <div class="section-title">⚡ Hardware</div>
  <div class="grid-3">
    <div class="stat-card"><div class="stat-icon">🧠</div><div class="stat-value">$CPU_COUNT</div><div class="stat-label">vCPU Cores</div></div>
    <div class="stat-card"><div class="stat-icon">💾</div><div class="stat-value">$TOTAL_RAM</div><div class="stat-label">Total RAM</div></div>
    <div class="stat-card"><div class="stat-icon">💿</div><div class="stat-value">$DISK_SIZE</div><div class="stat-label">Disk Size</div></div>
  </div>

  <div class="section-title">🐧 System</div>
  <div class="grid-2">
    <div class="card"><div class="label">OS Version</div><div class="value">$OS_VERSION</div></div>
    <div class="card"><div class="label">Kernel</div><div class="value">$KERNEL</div></div>
    <div class="card"><div class="label">Uptime</div><div class="value green">$UPTIME</div></div>
    <div class="card"><div class="label">Launched At</div><div class="value">$LAUNCHED_AT</div></div>
  </div>

  <div class="section-title">🔧 Debug Commands</div>
  <div class="terminal">
    <div><span class="t-prompt">$ </span><span class="t-cmd">sudo systemctl status nginx</span></div>
    <div><span class="t-prompt">$ </span><span class="t-cmd">sudo cat /var/log/cloud-init-output.log</span></div>
    <div><span class="t-prompt">$ </span><span class="t-cmd">curl http://169.254.169.254/latest/meta-data/instance-id</span></div>
    <div><span class="t-prompt">$ </span><span class="t-cmd">df -h && free -h && uptime</span></div>
    <div><span class="t-prompt">$ </span><span class="t-cmd">terraform output</span></div>
  </div>

  <div class="footer">
    Powered by <span>Terraform</span> &nbsp;•&nbsp; nginx on <span>Amazon Linux 2</span>
  </div>

</div>
</body>
</html>
HTML

# ─────────────────────────────────────────────
#   START NGINX
# ─────────────────────────────────────────────
systemctl enable nginx
systemctl start nginx

echo "✅ Done! Visit: http://$PUBLIC_IP"
