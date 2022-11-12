#!/bin/bash

#set -e
set -eux

echo "Config SSH ..."
export LOCAL_PUBLIC_KEY="xxxxx"
cat >> /home/ec2-user/.ssh/authorized_keys <<EOF
${LOCAL_PUBLIC_KEY}
EOF

echo "Config Code Server ..."
###############
#  VARIABLES  #
###############

CODE_SERVER_VERSION="4.5.2"
CODE_SERVER_INSTALL_LOC="/home/ec2-user/SageMaker/.cs"
XDG_DATA_HOME="/home/ec2-user/SageMaker/.xdg/data"
XDG_CONFIG_HOME="/home/ec2-user/SageMaker/.xdg/config"
CREATE_NEW_CONDA_ENV=1
CONDA_ENV_LOCATION='/home/ec2-user/SageMaker/.cs/conda/envs/codeserver_py39'
USE_CUSTOM_EXTENSION_GALLERY=0
EXTENSION_GALLERY_CONFIG='{{\"serviceUrl\":\"\",\"cacheUrl\":\"\",\"itemUrl\":\"\",\"controlUrl\":\"\",\"recommendationsUrl\":\"\"}}'

LAUNCHER_ENTRY_TITLE='Code Server'
PROXY_PATH='codeserver'
LAB_3_EXTENSION_DOWNLOAD_URL='https://github.com/aws-samples/amazon-sagemaker-codeserver/releases/download/v0.1.5/sagemaker-jproxy-launcher-ext-0.1.3.tar.gz'
INSTALL_LAB1_EXTENSION=1
LAB_1_EXTENSION_DOWNLOAD_URL='https://github.com/aws-samples/amazon-sagemaker-codeserver/releases/download/v0.1.5/amzn-sagemaker-jproxy-launcher-ext-jl1-0.1.4.tgz'

#############
#  INSTALL  #
#############

export XDG_DATA_HOME=$XDG_DATA_HOME
export XDG_CONFIG_HOME=$XDG_CONFIG_HOME
export PATH="${CODE_SERVER_INSTALL_LOC}/bin/:$PATH"

# use custom extension gallery
EXT_GALLERY_JSON=''
if [ $USE_CUSTOM_EXTENSION_GALLERY -eq 1 ]
then
    EXT_GALLERY_JSON="'EXTENSIONS_GALLERY': '$EXTENSION_GALLERY_CONFIG'"
fi

JUPYTER_CONFIG_FILE="/home/ec2-user/.jupyter/jupyter_notebook_config.py"
if grep -q "$CODE_SERVER_INSTALL_LOC/bin" "$JUPYTER_CONFIG_FILE"
then
    echo "Server-proxy configuration already set in Jupyter notebook config."
else
    cat >>/home/ec2-user/.jupyter/jupyter_notebook_config.py <<EOC
c.ServerProxy.servers = {
  '$PROXY_PATH': {
      'launcher_entry': {
            'enabled': True,
            'title': '$LAUNCHER_ENTRY_TITLE',
            'icon_path': 'codeserver.svg'
      },
      'command': ['$CODE_SERVER_INSTALL_LOC/bin/code-server', '--auth', 'none', '--disable-telemetry', '--bind-addr', '127.0.0.1:{port}'],
      'environment' : {
                        'XDG_DATA_HOME' : '$XDG_DATA_HOME',
                        'XDG_CONFIG_HOME': '$XDG_CONFIG_HOME',
                        'SHELL': '/bin/bash',
                        $EXT_GALLERY_JSON
                      },
      'absolute_url': False,
      'timeout': 30
  }
}
EOC
fi

JUPYTER_LAB_VERSION=$(/home/ec2-user/anaconda3/envs/JupyterSystemEnv/bin/jupyter-lab --version)

sudo -u ec2-user -i <<EOF
if [ $CREATE_NEW_CONDA_ENV -eq 1 ]
then
    conda config --add envs_dirs "${CONDA_ENV_LOCATION%/*}"
fi
if [[ $JUPYTER_LAB_VERSION == 1* ]]
then
    source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
    pip install jupyter-server-proxy
    conda deactivate
    if [ $INSTALL_LAB1_EXTENSION -eq 1 ]
    then
        rm -f $CODE_SERVER_INSTALL_LOC/install-jl1-extension.sh
        cat >>$CODE_SERVER_INSTALL_LOC/install-jl1-extension.sh <<- JL1EXT
sleep 15
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
mkdir -p $CODE_SERVER_INSTALL_LOC/lab_ext
curl -L $LAB_1_EXTENSION_DOWNLOAD_URL > $CODE_SERVER_INSTALL_LOC/lab_ext/amzn-sagemaker-jproxy-launcher-ext-jl1.tgz
cd $CODE_SERVER_INSTALL_LOC/lab_ext
jupyter labextension install amzn-sagemaker-jproxy-launcher-ext-jl1.tgz --no-build
jlpm config set cache-folder /tmp/yarncache
jupyter lab build --debug --minimize=False
conda deactivate
JL1EXT
        chmod +x $CODE_SERVER_INSTALL_LOC/install-jl1-extension.sh
        sh $CODE_SERVER_INSTALL_LOC/install-jl1-extension.sh
    fi
else
    source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
    # Install JL3 extension
    mkdir -p $CODE_SERVER_INSTALL_LOC/lab_ext
    curl -L $LAB_3_EXTENSION_DOWNLOAD_URL > $CODE_SERVER_INSTALL_LOC/lab_ext/sagemaker-jproxy-launcher-ext.tar.gz
    pip install $CODE_SERVER_INSTALL_LOC/lab_ext/sagemaker-jproxy-launcher-ext.tar.gz
    jupyter labextension disable jupyterlab-server-proxy
    conda deactivate
fi
EOF

systemctl restart jupyter-server

echo "Generate start-tf29-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/start-tf29-p38.sh <<EOD
#!/bin/bash

set -e

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf29-p38
source "\$WORKING_DIR/miniconda/bin/activate"
for env in \$WORKING_DIR/miniconda/envs/*; do
    BASENAME=\$(basename "\$env")
    source activate "\$BASENAME"
    python -m ipykernel install --user --name "\$BASENAME" --display-name "Custom (\$BASENAME)"
done
# Optionally, uncomment these lines to disable SageMaker-provided Conda functionality.
# echo "c.EnvironmentKernelSpecManager.use_conda_directly = False" >> /home/ec2-user/.jupyter/jupyter_notebook_config.py
# rm /home/ec2-user/.condarc
EOF

echo "Restarting the Jupyter server ..."
sudo systemctl restart jupyter-server

EOD


echo "Generate start-tf28-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/start-tf28-p38.sh <<EOD
#!/bin/bash

set -e

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf28-p38
source "\$WORKING_DIR/miniconda/bin/activate"
for env in \$WORKING_DIR/miniconda/envs/*; do
    BASENAME=\$(basename "\$env")
    source activate "\$BASENAME"
    python -m ipykernel install --user --name "\$BASENAME" --display-name "Custom (\$BASENAME)"
done
EOF

echo "Restarting the Jupyter server ..."
sudo systemctl restart jupyter-server

EOD


echo "Generate start-tf27-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/start-tf27-p38.sh <<EOD
#!/bin/bash

set -e

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf27-p38
source "\$WORKING_DIR/miniconda/bin/activate"
for env in \$WORKING_DIR/miniconda/envs/*; do
    BASENAME=\$(basename "\$env")
    source activate "\$BASENAME"
    python -m ipykernel install --user --name "\$BASENAME" --display-name "Custom (\$BASENAME)"
done
EOF

echo "Restarting the Jupyter server ..."
sudo systemctl restart jupyter-server

EOD

echo "Generate start-tf26-p38.sh ..."
cat > /home/ec2-user/SageMaker/custom/start-tf26-p38.sh <<EOD
#!/bin/bash

set -e

sudo -u ec2-user -i <<'EOF'
unset SUDO_UID
WORKING_DIR=/home/ec2-user/SageMaker/custom/tf26-p38
source "\$WORKING_DIR/miniconda/bin/activate"
for env in \$WORKING_DIR/miniconda/envs/*; do
    BASENAME=\$(basename "\$env")
    source activate "\$BASENAME"
    python -m ipykernel install --user --name "\$BASENAME" --display-name "Custom (\$BASENAME)"
done
EOF

echo "Restarting the Jupyter server ..."
sudo systemctl restart jupyter-server

EOD



sudo chmod +x /home/ec2-user/SageMaker/custom/*.sh
sudo chown ec2-user:ec2-user /home/ec2-user/SageMaker/custom/ -R