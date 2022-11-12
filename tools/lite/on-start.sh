#!/bin/bash

#set -e
set -eux

# kite
# with systemd, run systemctl --user start kite-autostart
# without systemd, run /home/ec2-user/.local/share/kite/kited
# or launch it using the Applications Menu

systemctl restart jupyter-server

sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R