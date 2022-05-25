#!/bin/bash
touch "${INFO_PATH}"/WAIT_FOR_REBOOTING

cat << EOF > "${MAIN_PATH}"/cancel_reboot_signal.sh
#!/bin/bash
systemctl disable reboot_check.service
systemctl daemon-reload
rm -rf /etc/systemd/system/reboot_check.service "${INFO_PATH}"/WAIT_FOR_REBOOTING "${MAIN_PATH}"/cancel_reboot_signal.sh
EOF

chmod 755 "${MAIN_PATH}"/cancel_reboot_signal.sh
cat << EOF > /etc/systemd/system/reboot_check.service
[Unit]
Description=Setup
After=network.target
[Service]
Type=oneshot
ExecStart="${MAIN_PATH}"/cancel_reboot_signal.sh
RemainAfterExit=true
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable reboot_check.service > /dev/null 2>&1
