#!/usr/bin/env bash

echo "Setting up ssh with ngrok..."

echo "Setup ngrok..."
curl https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz > ngrok.tgz
tar -xvf ngrok.tgz && sudo mv ngrok /usr/bin/
chown ec2-user:ec2-user /usr/bin/ngrok

echo "Creating config file /home/ec2-user/SageMaker/.ngrok/ngrok.yml..."
mkdir -p /home/ec2-user/SageMaker/ngrok
if [[ ! -e /home/ec2-user/SageMaker/ngrok/ngrok.yml ]]; then
    cat > /home/ec2-user/SageMaker/ngrok/ngrok.yml << EOF

authtoken: $NGROK_AUTH_TOKEN

tunnels:
    ssh:
        proto: tcp
        addr: 22

version: "2"
EOF
    chown -R ec2-user:ec2-user /home/ec2-user/SageMaker/ngrok
fi

# start-ngrok-ssh script
echo "Creating /usr/bin/start-ngrok-ssh..."
cat > /usr/bin/start-ngrok-ssh <<'EOF'
#!/usr/bin/env bash

set -e

echo "Starting ngrok..."
ngrok start --all --log=stdout --config /home/ec2-user/SageMaker/ngrok/ngrok.yml > /home/ec2-user/SageMaker/ngrok/ngrok.log & sleep 10

TUNNEL_URL=$(grep -Eo 'url=.+' /home/ec2-user/SageMaker/ngrok/ngrok.log | cut -d= -f2)
if [[ -z $TUNNEL_URL ]]; then
    echo "Failed to set up ssh with ngrok"
    echo "Ngrok logs:"
    cat /home/ec2-user/SageMaker/ngrok/ngrok.log
fi

echo "SSH address ${TUNNEL_URL}"

cat > /home/ec2-user/SageMaker/ngrok/SSH_TIPS <<EOD
SSH enabled through ngrok!
Address: ${TUNNEL_URL}

Use 'ssh -p <port_from_above> ec2-user@<host_from_above>' to SSH here!
EOD
EOF
chmod +x /usr/bin/start-ngrok-ssh
chown ec2-user:ec2-user /usr/bin/start-ngrok-ssh

# manually add your ssh public key
# copy-ssh-keys script
#mkdir -p /home/ec2-user/.ssh && chown ec2-user:ec2-user /home/ec2-user/.ssh
#mkdir -p /home/ec2-user/SageMaker/ssh && chown -R ec2-user:ec2-user /home/ec2-user/SageMaker/ssh
#cat > /usr/bin/copy-ssh-keys <<'EOF'
##!/usr/bin/env bash
#
#set -e
#
#touch /home/ec2-user/SageMaker/ssh/authorized_keys
#chown ec2-user:ec2-user /home/ec2-user/SageMaker/ssh/authorized_keys
#
#cnt=$(cat /home/ec2-user/SageMaker/ssh/authorized_keys | wc -l)
#echo "Copying ${cnt} SSH keys..."
#cp /home/ec2-user/SageMaker/ssh/authorized_keys /home/ec2-user/.ssh/authorized_keys
#EOF
#chmod +x /usr/bin/copy-ssh-keys
#chown ec2-user:ec2-user /usr/bin/copy-ssh-keys
#
#copy-ssh-keys

start-ngrok-ssh