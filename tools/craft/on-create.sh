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

echo "Install Code Server ..."
###############
#  VARIABLES  #
###############

CODE_SERVER_VERSION="4.5.2"
CODE_SERVER_INSTALL_LOC="/home/ec2-user/SageMaker/.cs"
XDG_DATA_HOME="/home/ec2-user/SageMaker/.xdg/data"
XDG_CONFIG_HOME="/home/ec2-user/SageMaker/.xdg/config"
INSTALL_PYTHON_EXTENSION=1
CREATE_NEW_CONDA_ENV=1
CONDA_ENV_LOCATION='/home/ec2-user/SageMaker/.cs/conda/envs/codeserver_py39'
CONDA_ENV_PYTHON_VERSION="3.9"
INSTALL_DOCKER_EXTENSION=1
USE_CUSTOM_EXTENSION_GALLERY=0

sudo -u ec2-user -i <<EOF
unset SUDO_UID
#############
#  INSTALL  #
#############
# set the data and config home env variable for code-server
export XDG_DATA_HOME=$XDG_DATA_HOME
export XDG_CONFIG_HOME=$XDG_CONFIG_HOME
export PATH="$CODE_SERVER_INSTALL_LOC/bin/:$PATH"
# install code-server standalone
mkdir -p ${CODE_SERVER_INSTALL_LOC}/lib ${CODE_SERVER_INSTALL_LOC}/bin
curl -fL https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VERSION/code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz \
| tar -C ${CODE_SERVER_INSTALL_LOC}/lib -xz
mv ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION-linux-amd64 ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION
ln -s ${CODE_SERVER_INSTALL_LOC}/lib/code-server-$CODE_SERVER_VERSION/bin/code-server ${CODE_SERVER_INSTALL_LOC}/bin/code-server
# create separate conda environment
if [ $CREATE_NEW_CONDA_ENV -eq 1 ]
then
    conda create --prefix $CONDA_ENV_LOCATION python=$CONDA_ENV_PYTHON_VERSION -y
fi
# install ms-python extension
if [ $USE_CUSTOM_EXTENSION_GALLERY -eq 0 -a $INSTALL_PYTHON_EXTENSION -eq 1 ]
then
    code-server --install-extension ms-python.python --force
    # if the new conda env was created, add configuration to set as default
    if [ $CREATE_NEW_CONDA_ENV -eq 1 ]
    then
        CODE_SERVER_MACHINE_SETTINGS_FILE="$XDG_DATA_HOME/code-server/Machine/settings.json"
        if grep -q "python.defaultInterpreterPath" "\$CODE_SERVER_MACHINE_SETTINGS_FILE"
        then
            echo "Default interepreter path is already set."
        else
            cat >>\$CODE_SERVER_MACHINE_SETTINGS_FILE <<- MACHINESETTINGS
{
    "python.defaultInterpreterPath": "$CONDA_ENV_LOCATION/bin"
}
MACHINESETTINGS
        fi
    fi
fi
# install docker extension
if [ $USE_CUSTOM_EXTENSION_GALLERY -eq 0 -a $INSTALL_DOCKER_EXTENSION -eq 1 ]
then
    code-server --install-extension ms-azuretools.vscode-docker --force
fi
EOF


echo "Create custom folder ..."
mkdir -p /home/ec2-user/SageMaker/custom

echo "Download prepareNotebook.sh ..."
wget https://raw.githubusercontent.com/AIMLTOP/tensorflow-deep-learning/main/tools/prepareNotebook.sh -O /home/ec2-user/SageMaker/custom/prepareNotebook.sh


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


echo "Generate create-tf28-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/create-tf28-p38.sh <<EOD
#!/bin/bash

set -e

echo "Setup Custom Kernel ..."

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
# Install a separate conda installation via Miniconda
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf28-p38
mkdir -p "\$WORKING_DIR"
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.11.0-Linux-x86_64.sh -O "\$WORKING_DIR/miniconda.sh"

bash "\$WORKING_DIR/miniconda.sh" -b -u -p "\$WORKING_DIR/miniconda"
rm -rf "\$WORKING_DIR/miniconda.sh"
# Create a custom conda environment
source "\$WORKING_DIR/miniconda/bin/activate"
KERNEL_NAME="tf28_p38"
PYTHON="3.8"
conda create --yes --name "\$KERNEL_NAME" python="\$PYTHON"
conda activate "\$KERNEL_NAME"
pip install --quiet ipykernel
# Customize these lines as necessary to install the required packages
conda install --yes tensorflow==2.8.2 tensorflow-datasets Pillow pandas numpy scipy
pip install --quiet boto3 sagemaker
conda install --yes matplotlib jupyter scikit-learn seaborn beautifulsoup4
conda deactivate
EOF

EOD

echo "Generate create-tf27-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/create-tf27-p38.sh <<EOD
#!/bin/bash

set -e

echo "Setup Custom Kernel ..."

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
# Install a separate conda installation via Miniconda
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf27-p38
mkdir -p "\$WORKING_DIR"
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.11.0-Linux-x86_64.sh -O "\$WORKING_DIR/miniconda.sh"

bash "\$WORKING_DIR/miniconda.sh" -b -u -p "\$WORKING_DIR/miniconda"
rm -rf "\$WORKING_DIR/miniconda.sh"
# Create a custom conda environment
source "\$WORKING_DIR/miniconda/bin/activate"
KERNEL_NAME="tf27_p38"
PYTHON="3.8"
conda create --yes --name "\$KERNEL_NAME" python="\$PYTHON"
conda activate "\$KERNEL_NAME"
pip install --quiet ipykernel
# Customize these lines as necessary to install the required packages
conda install --yes tensorflow==2.7.1 tensorflow-datasets sagemaker
conda install --yes Pillow pandas numpy scipy matplotlib jupyter scikit-learn seaborn beautifulsoup4
conda deactivate
EOF

EOD

echo "Generate create-tf26-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/create-tf26-p38.sh <<EOD
#!/bin/bash

set -e

echo "Setup Custom Kernel ..."

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
# Install a separate conda installation via Miniconda
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf26-p38
mkdir -p "\$WORKING_DIR"
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.11.0-Linux-x86_64.sh -O "\$WORKING_DIR/miniconda.sh"

bash "\$WORKING_DIR/miniconda.sh" -b -u -p "\$WORKING_DIR/miniconda"
rm -rf "\$WORKING_DIR/miniconda.sh"
# Create a custom conda environment
source "\$WORKING_DIR/miniconda/bin/activate"
KERNEL_NAME="tf26_p38"
PYTHON="3.8"
conda create --yes --name "\$KERNEL_NAME" python="\$PYTHON"
conda activate "\$KERNEL_NAME"
pip install --quiet ipykernel
# Customize these lines as necessary to install the required packages
conda install --yes tensorflow==2.6.2 tensorflow-datasets sagemaker
conda install --yes Pillow pandas numpy scipy matplotlib jupyter scikit-learn seaborn beautifulsoup4
conda deactivate
EOF

EOD


sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R