#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx curl wget git htop

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
HOSTNAME=$(hostname)
CPU_COUNT=$(nproc)
TOTAL_RAM=$(free -h | awk '/^Mem:/{print $2}')
DISK_SIZE=$(df -h / | awk 'NR==2{print $2}')
LAUNCHED_AT=$(date '+%Y-%m-%d %H:%M:%S UTC')

# Write HTML using printf to avoid heredoc conflicts
printf '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>EC2 Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Segoe UI, sans-serif; background: #030712; color: #e2e8f0; min-height: 100vh; padding: 40px 20px; }
    .container { max-width: 800px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 36px; }
    .badge { display: inline-flex; align-items: center; gap: 6px; background: #052e16; border: 1px solid #166534; color: #4ade80; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-bottom: 14px; }
    .dot { width: 7px; height: 7px; background: #4ade80; border-radius: 50%%; animation: pulse 1.5s infinite; }
    @keyframes pulse { 0%%,100%%{opacity:1} 50%%{opacity:0.3} }
    h1 { font-size: 32px; font-weight: 700; background: linear-gradient(135deg, #38bdf8, #818cf8, #f472b6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 6px; }
    .subtitle { color: #64748b; font-size: 14px; }
    .section { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: #475569; margin: 28px 0 10px; display: flex; align-items: center; gap: 8px; }
    .section::after { content: ""; flex: 1; height: 1px; background: #1e293b; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
    .card { background: #0f172a; border: 1px solid #1e293b; border-radius: 10px; padding: 14px 16px; }
    .card .label { font-size: 11px; text-transform: uppercase; color: #475569; margin-bottom: 5px; }
    .card .value { font-size: 13px; font-weight: 600; word-break: break-all; }
    .blue { color: #38bdf8; } .green { color: #4ade80; } .purple { color: #a78bfa; } .orange { color: #fb923c; }
    .stat { background: #0f172a; border: 1px solid #1e293b; border-radius: 10px; padding: 18px; text-align: center; }
    .stat .icon { font-size: 24px; margin-bottom: 6px; }
    .stat .sval { font-size: 20px; font-weight: 700; }
    .stat .slabel { font-size: 12px; color: #64748b; margin-top: 3px; }
    .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #1e293b; color: #334155; font-size: 13px; }
    .footer span { color: #f97316; font-weight: 600; }
  </style>
</head>
<body>
<div class="container">
  <div class="header">
    <div class="badge"><div class="dot"></div> LIVE</div>
    <h1>EC2 Instance Dashboard</h1>
    <p class="subtitle">Deployed with Terraform + UserData &nbsp; Ubuntu</p>
  </div>
  <div class="section">Instance</div>
  <div class="grid-2">
    <div class="card"><div class="label">Instance ID</div><div class="value blue">'"$INSTANCE_ID"'</div></div>
    <div class="card"><div class="label">Instance Type</div><div class="value purple">'"$INSTANCE_TYPE"'</div></div>
    <div class="card"><div class="label">Hostname</div><div class="value">'"$HOSTNAME"'</div></div>
    <div class="card"><div class="label">Launched At</div><div class="value">'"$LAUNCHED_AT"'</div></div>
  </div>
  <div class="section">Network</div>
  <div class="grid-2">
    <div class="card"><div class="label">Public IP</div><div class="value green">'"$PUBLIC_IP"'</div></div>
    <div class="card"><div class="label">Private IP</div><div class="value">'"$PRIVATE_IP"'</div></div>
    <div class="card"><div class="label">Region</div><div class="value orange">'"$REGION"'</div></div>
    <div class="card"><div class="label">Availability Zone</div><div class="value">'"$AZ"'</div></div>
  </div>
  <div class="section">Hardware</div>
  <div class="grid-3">
    <div class="stat"><div class="icon">🧠</div><div class="sval">'"$CPU_COUNT"'</div><div class="slabel">vCPU Cores</div></div>
    <div class="stat"><div class="icon">💾</div><div class="sval">'"$TOTAL_RAM"'</div><div class="slabel">Total RAM</div></div>
    <div class="stat"><div class="icon">💿</div><div class="sval">'"$DISK_SIZE"'</div><div class="slabel">Disk Size</div></div>
  </div>
  <div class="footer">Powered by <span>Terraform</span> &nbsp; nginx on <span>Ubuntu</span></div>
</div>
</body>
</html>' > /var/www/html/index.html

systemctl enable nginx
systemctl start nginx

echo "✅ Done! Visit: http://$PUBLIC_IP"s