#!/bin/bash

#set -e
set -eux

echo "Install Extensions ..."
sudo -u ec2-user -i <<'EOF'

# conda install -c conda-forge nodejs
source activate JupyterSystemEnv
jupyter labextension install jupyterlab-s3-browser
pip install jupyterlab-s3-browser
jupyter serverextension enable --py jupyterlab_s3_browser

pip install jupyterlab-lsp
pip install 'python-lsp-server[all]'
jupyter server extension enable --user --py jupyter_lsp

sudo systemctl restart jupyter-server
# source deactivate
EOF

echo "Create custom folder ..."
mkdir -p /home/ec2-user/SageMaker/custom

echo "Download prepareNotebook.sh ..."
wget https://raw.githubusercontent.com/AIMLTOP/tensorflow-deep-learning/main/tools/prepareNotebook.sh -O /home/ec2-user/SageMaker/custom/prepareNotebook.sh

sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R