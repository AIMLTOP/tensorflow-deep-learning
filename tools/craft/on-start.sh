#!/bin/bash

#set -e
set -eux

echo "Config SSH ..."
export LOCAL_PUBLIC_KEY="xxxxx"
cat >> /home/ec2-user/.ssh/authorized_keys <<EOF
${LOCAL_PUBLIC_KEY}
EOF

# kite
# with systemd, run systemctl --user start kite-autostart
# without systemd, run /home/ec2-user/.local/share/kite/kited
# or launch it using the Applications Menu

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