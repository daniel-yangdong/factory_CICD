#!/bin/bash

# Install dependencies
apt update && apt install -y python3 python3-pip ipmitool stress memtester ethtool nvme-cli smartmontools

# Install Python packages
pip3 install -r /opt/diag-agent/requirements.txt

# Copy agent files
cp -r /opt/diag-agent /opt/

# Enable and start systemd service
systemctl enable /opt/diag-agent/systemd/diag-agent.service
systemctl start diag-agent