

## SSH Setup
1. Local Machine Generate SSH Key

```shell
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/sagemaker
```

2. SageMaker Notebook

Add local public key to authorized_keys
```shell
vi ~/.ssh/authorized_keys
```

3. (Optional) Setup DNS


4. Update Local Machine SSH Config

```shell
Host nlb-sagemaker-proxy-*.amazonaws.com
    ServerAliveInterval 360
    AddKeysToAgent yes
    IdentityFile ~/.ssh/sagemaker
    IdentitiesOnly=yes
```

5. SSH from Local Machine

```shell
ssh ec2-user@nlb-sagemaker-proxy-xxxxx.amazonaws.com
```


## Integration

Refs:
- https://www.jetbrains.com/help/pycharm/configuring-remote-interpreters-via-ssh.html#ssh-credentials
- https://www.jetbrains.com/help/pycharm/creating-a-remote-server-configuration.html

1. Pycharm Add SSH interpreter

- 输入NLB/DNS地址
- 用户名 ec2-user

2. Pycharm interpreter and Sync folders

- /home/ec2-user/anaconda3/bin/python
- /home/ec2-user/SageMaker/1Laptop/


