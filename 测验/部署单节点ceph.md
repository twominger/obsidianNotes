```shell

```

 ```shell
yum -y install python3
yum -y install lvm2
yum -y install podman
```

```shell
cat >/etc/chrony.conf <<EOF
pool ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 172.16.1.0/24
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd
chronyc sources
```

```shell
wget http://lab4.cn/cephadm
chmod +x cephadm
./cephadm add-repo --release pacific
./cephadm install/
cephadm install ceph-common

vim /usr/sbin/cephadm
# 替换以下参数


```