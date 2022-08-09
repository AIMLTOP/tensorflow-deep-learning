#!/bin/bash
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

EOF