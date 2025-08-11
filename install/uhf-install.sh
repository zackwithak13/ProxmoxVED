#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: zackwithak13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.uhfapp.com/server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get -y install ffmpeg
msg_ok "Installed Dependencies"

msg_info "Setting Up UHF Server Environment"
mkdir -p /etc/uhf-server
mkdir -p /var/lib/uhf-server/data
mkdir -p /var/lib/uhf-server/recordings
cat <<EOF >/etc/uhf-server/.env
API_HOST=0.0.0.0
API_PORT=7568
RECORDINGS_DIR=/var/lib/uhf-server/recordings
DB_PATH=/var/lib/uhf-server/data/db.json
LOG_LEVEL=INFO
EOF
msg_ok "Set Up UHF Server Environment"
fetch_and_deploy_gh_release "comskip" "swapplications/comskip" "prebuild" "latest" "/opt/comskip" "comskip-x64-*.zip"
fetch_and_deploy_gh_release "uhf-server" "swapplications/uhf-server-dist" "prebuild" "latest" "/opt/uhf-server" "UHF.Server-linux-x64-*.zip"

msg_info "Creating Service"
service_path=""
cat <<EOF >/etc/systemd/system/uhf-server.service
echo "[Unit]
Description=UHF Server service
After=syslog.target network-online.target
[Service]
Type=simple
WorkingDirectory=/opt/uhf-server
EnvironmentFile=/etc/uhf-server/.env
ExecStart=/opt/uhf-server/uhf-server
[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q uhf-server.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
