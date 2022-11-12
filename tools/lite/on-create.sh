#!/bin/bash

#set -e
set -eux

echo "Install Extensions ..."
sudo -u ec2-user -i <<'EOF'

# conda install -c conda-forge nodejs

# Chose Kite or jupyterlab-lsp, Not Both
# Kite Engine
#bash -c "$(wget -q -O - https://linux.kite.com/dls/linux/current)"
yes "" | bash -c "$(wget -q -O - https://linux.kite.com/dls/linux/current)"

source activate JupyterSystemEnv

# https://github.com/kiteco/jupyterlab-kite
pip install "jupyterlab-kite>=2.0.2"

#pip install jupyterlab-lsp
#pip install 'python-lsp-server[all]'
#jupyter server extension enable --user --py jupyter_lsp

jupyter labextension install jupyterlab-s3-browser
pip install jupyterlab-s3-browser
jupyter serverextension enable --py jupyterlab_s3_browser

# https://github.com/lckr/jupyterlab-variableInspector
pip install lckr-jupyterlab-variableinspector

# https://github.com/matplotlib/ipympl
pip install ipympl

# https://github.com/aquirdTurtle/Collapsible_Headings
pip install aquirdturtle_collapsible_headings

# https://github.com/QuantStack/jupyterlab-drawio
pip install jupyterlab-drawio

# https://github.com/jtpio/jupyterlab-system-monitor
pip install jupyterlab-system-monitor

# https://github.com/deshaw/jupyterlab-execute-time
pip install jupyterlab_execute_time

# jupyterlab_tabnine https://www.tabnine.com/install/jupyterlab
#pip3 install jupyterlab_tabnine # 不好用

sudo systemctl restart jupyter-server
# source deactivate
EOF

echo "Create sh profile  ..."
echo "alias b='/bin/bash'" > ~/.profile

echo "Create custom folder ..."
mkdir -p /home/ec2-user/SageMaker/custom

echo "Download prepareNotebook.sh ..."
wget https://raw.githubusercontent.com/AIMLTOP/tensorflow-deep-learning/main/tools/prepareNotebook.sh -O /home/ec2-user/SageMaker/custom/prepareNotebook.sh

sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R