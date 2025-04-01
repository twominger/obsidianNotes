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
wget https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm
./cephadm add-repo --release pacific
./cephadm install
cephadm install ceph-common

vim /usr/sbin/cephadm
# 替换以下参数

DEFAULT_IMAGE = 'uhub.service.ucloud.cn/cl260/ceph:v16' 
DEFAULT_IMAGE_IS_MASTER = False 
DEFAULT_IMAGE_RELEASE = 'pacific' 
DEFAULT_PROMETHEUS_IMAGE = 'uhub.service.ucloud.cn/cl260/prometheus:v2.33.4' 
DEFAULT_NODE_EXPORTER_IMAGE = 'uhub.service.ucloud.cn/cl260/node-exporter:v1.3.1' 
DEFAULT_ALERT_MANAGER_IMAGE = 'uhub.service.ucloud.cn/cl260/alertmanager:v0.23.0' 
DEFAULT_GRAFANA_IMAGE = 'uhub.service.ucloud.cn/cl260/ceph-grafana:8.3.5' 
DEFAULT_HAPROXY_IMAGE = 'uhub.service.ucloud.cn/cl260/haproxy:2.3' 
DEFAULT_KEEPALIVED_IMAGE = 'uhub.service.ucloud.cn/cl260/keepalived' 
DEFAULT_SNMP_GATEWAY_IMAGE = 'uhub.service.ucloud.cn/cl260/snmp-notifier:v1.2.1' 
DEFAULT_REGISTRY = 'docker.io' # normalize unqualified digests to this


```