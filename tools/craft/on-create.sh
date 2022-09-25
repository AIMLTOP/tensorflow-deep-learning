#!/bin/bash

set -e

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
source deactivate
EOF

mkdir -p /home/ec2-user/SageMaker/custom

echo "Generate create-tf29-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/create-tf29-p38.sh <<EOD
#!/bin/bash

set -e

echo "Setup Custom Kernel ..."

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
# Install a separate conda installation via Miniconda
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf29-p38
mkdir -p "\$WORKING_DIR"
# wget https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh -O "\$WORKING_DIR/miniconda.sh"
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.11.0-Linux-x86_64.sh -O "\$WORKING_DIR/miniconda.sh"

bash "\$WORKING_DIR/miniconda.sh" -b -u -p "\$WORKING_DIR/miniconda"
rm -rf "\$WORKING_DIR/miniconda.sh"
# Create a custom conda environment
source "\$WORKING_DIR/miniconda/bin/activate"
KERNEL_NAME="tf29_p38"
PYTHON="3.8"
conda create --yes --name "\$KERNEL_NAME" python="\$PYTHON"
conda activate "\$KERNEL_NAME"
pip install --quiet ipykernel
# Customize these lines as necessary to install the required packages
# conda install --yes numpy
conda install --yes Pillow==9.1.1 pandas==1.4.2 numpy==1.22.4 scipy==1.7.3
pip install tensorflow==2.9.0 tensorflow-datasets==4.6.0
#conda install --yes tensorflow==2.9.1 tensorflow-datasets==4.6.0
pip install --quiet boto3 sagemaker
#pip install sagemaker
conda install --yes matplotlib jupyter scikit-learn seaborn beautifulsoup4
#source deactivate
conda deactivate
EOF

EOD

sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R