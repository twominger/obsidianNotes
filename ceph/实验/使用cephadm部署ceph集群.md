# 实验环境
- 虚拟化平台：VMware Workstation
- 操作系统版本：[CentOS 8.4.2105](https://vault.centos.org/8.4.2105/)
- 需要四台虚拟机（至少三台），双网卡（ens160 作为外部网络、ens192 作为集群网络），每台虚拟机一个系统盘，三个 10G数据盘

|  主机名  |                     IP                     |                网关/DNS                 |  规格   | 系统盘 |  数据盘  |    角色     |
| :---: | :----------------------------------------: | :-----------------------------------: | :---: | :-: | :---: | :-------: |
| node1 | 192.168.44.81(NAT)<br>172.16.1.81(仅主机)<br> | 192.168.44.2/114.114.114.114<br>/<br> | 2c/4g | 随意  | 10G*3 | 集群主机+引导节点 |
| node2 | 192.168.44.82(NAT)<br>172.16.1.82(仅主机)<br> | 192.168.44.2/114.114.114.114<br>/<br> | 2c/4g | 随意  | 10G*3 |   集群主机    |
| node3 | 192.168.44.83(NAT)<br>172.16.1.83(仅主机)<br> | 192.168.44.2/114.114.114.114<br>/<br> | 2c/4g | 随意  | 10G*3 |   集群主机    |
| node4 |   192.168.44.84(NAT)<br>172.16.1.84(仅主机)   | 192.168.44.2/114.114.114.114<br>/<br> | 2c/4g | 随意  | 10G*3 |   集群主机    |
# 实验环境搭建
## 关闭防火墙和 SELinux 并重启（所有节点）
```shell
systemctl disable firewalld --now

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

reboot
```
> [! 注意 ]
> 此处一定要重启
## 主机名、网络、IP 映射（所有节点）
- **前提：** 设置 nmcli 的 connection name 为 ens160（集群网络） 和 ens192（外部网络）
1. 检查 ` /etc/sysconfig/network-scripts/` 下的配置文件，没有则手动创建
```shell
cat >/etc/sysconfig/network-scripts/ifcfg-ens160 <<EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens160
DEVICE=ens160
ONBOOT=yes
EOF
cat >/etc/sysconfig/network-scripts/ifcfg-ens192 <<EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens192
DEVICE=ens192
ONBOOT=yes
EOF

systemctl restart NetworkManager
nmcli connection reload
reboot # 最好重启一下
```
2. 设置 con-name
```shell
nmcli connection show
nmcli connection modify <原NAME> con-name ens160
nmcli connection modify <原NAME> con-name ens192
# 注意比对网卡配置文件里的 UUID 与 connection 的 UUID 一致
```
3. 重启
### node1
- 主机名+网络
```shell
hostnamectl set-hostname node1
nmcli connection modify ens160 ipv4.addresses 192.168.44.81/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
nmcli connection modify ens192 ipv4.addresses 172.16.1.81/24 ipv4.method manual
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
nmcli connection down ens192
nmcli connection up ens192
```
- IP 映射
```shell
cat >>/etc/hosts <<EOF
172.16.1.81 node1.ming.com node1
172.16.1.82 node2.ming.com node2
172.16.1.83 node3.ming.com node3
172.16.1.84 node4.ming.com node4
EOF
```
### node2
- 主机名+网络
```shell
hostnamectl set-hostname node2
nmcli connection modify ens160 ipv4.addresses 192.168.44.82/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
nmcli connection modify ens192 ipv4.addresses 172.16.1.82/24 ipv4.method manual
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
nmcli connection down ens192
nmcli connection up ens192
```
- IP 映射
```shell
cat >>/etc/hosts <<EOF
172.16.1.81 node1.ming.com node1
172.16.1.82 node2.ming.com node2
172.16.1.83 node3.ming.com node3
172.16.1.84 node4.ming.com node4
EOF
```
### node3
- 主机名+网络
```shell
hostnamectl set-hostname node3
nmcli connection modify ens160 ipv4.addresses 192.168.44.83/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
nmcli connection modify ens192 ipv4.addresses 172.16.1.83/24 ipv4.method manual
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
nmcli connection down ens192
nmcli connection up ens192
```
- IP 映射
```shell
cat >>/etc/hosts <<EOF
172.16.1.81 node1.ming.com node1
172.16.1.82 node2.ming.com node2
172.16.1.83 node3.ming.com node3
172.16.1.84 node4.ming.com node4
EOF
```
### node4
- 主机名+网络
```shell
hostnamectl set-hostname node4
nmcli connection modify ens160 ipv4.addresses 192.168.44.84/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
nmcli connection modify ens192 ipv4.addresses 172.16.1.84/24 ipv4.method manual
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
nmcli connection down ens192
nmcli connection up ens192
```
- IP 映射
```shell
cat >>/etc/hosts <<EOF
172.16.1.81 node1.ming.com node1
172.16.1.82 node2.ming.com node2
172.16.1.83 node3.ming.com node3
172.16.1.84 node4.ming.com node4
EOF
```
### 网络配置好后可以使用 xshell 远程连接
## yum 源（所有节点）
```shell
mkdir /etc/yum.repos.d/bak 
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/

cat <<EOF > /etc/yum.repos.d/cloudcs.repo
[BaseOS]
name = BaseOS
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/BaseOS/x86_64/os/
gpgcheck = 0
[AppStream]
name = AppStream
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/AppStream/x86_64/os/
gpgcheck = 0
[centos-advanced-virtualization]
name = centos-advanced-virtualization
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/virt/x86_64/advanced-virtualization/
gpgcheck = 0
[centos-ceph-pacific]
name = centos-ceph-nautilus
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/storage/x86_64/ceph-pacific/
gpgcheck = 0
[centos-nfv-openvswitch]
name = centos-nfv-openvswitch
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/nfv/x86_64/openvswitch-2/
gpgcheck = 0
[centos-openstack-victoria]
name = centos-openstack-victoria
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/cloud/x86_64/openstack-victoria/
gpgcheck = 0
[centos-rabbitmq-38]
name = centos-rabbitmq-38
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/messaging/x86_64/rabbitmq-38/
gpgcheck = 0
[extras]
name = extras
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/extras/x86_64/os/
gpgcheck = 0
[PowerTools]
name = PowerTools
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/PowerTools/x86_64/os/
gpgcheck = 0
EOF
```
## 安装必要依赖
```shell
yum -y install python3
yum -y install lvm2
yum -y install podman
systemctl enable podman --now
```
- 安装其他包
```shell
yum -y install bash-completion
yum -y install net-tools
yum -y install vim
yum -y install bind-utils
yum -y install policycoreutils-python-utils
yum -y install wget
yum -y install tar
yum -y install yum-utils
yum -y install chrony
```
## 配置时间同步（所有节点）
### node1（作为主时间源）
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
### node2、3、4（同步 node1）
```shell
cat >/etc/chrony.conf <<EOF
pool node1 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd
chronyc sources
```
# cephadm 安装单节点集群
## 获取指定版本 cephadm 脚本
```shell
wget https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm
```
## 添加指定版本 ceph 源
```shell
./cephadm add-repo --release pacific
```
## 安装 cephadm
```shell
./cephadm install
```
## 安装 ceph 客户端工具
```shell
cephadm install ceph-common
```
## 修改 cephadm 容器仓库
- 可先尝试[[#在引导节点上部署单节点 mon 集群|下一步]]，不行的话再进行修改
因为 cephadm 在 rockyLinux 上默认使用的 quay.io 的容器仓库，国内拉取速度非常 慢甚至无法拉取，因此需要修改 cephadm 工具的容器仓库
```shell
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
## 在引导节点上部署单节点 mon 集群
```shell
cephadm bootstrap --mon-ip 172.16.1.81 --allow-fqdn-hostname --initial-dashboard-user admin --initial-dashboard-password redhat --dashboard-password-noupdate
```
# 为单节点集群扩展服务
## 给单节点集群添加 OSD 磁盘
```shell
cephadm shell
ceph orch daemon add osd node1:/dev/sdb
ceph orch daemon add osd node1:/dev/sdc
ceph orch daemon add osd node1:/dev/sdd
```
## 给集群添加主机
```shell
ceph cephadm get-pub-key > ~/ceph.pub # 获取集群公钥
ssh-copy-id -f -i ~/ceph.pub root@node2
ssh-copy-id -f -i ~/ceph.pub root@node3
ssh-copy-id -f -i ~/ceph.pub root@node4

ceph orch host add node2
ceph orch host add node3
ceph orch host add node4
```
## 添加 mgr 节点
```shell
ceph orch daemon add --placement=node2
```
## 添加 mon 节点
```shell
ceph orch daemon add mon node2
```
## 自动添加集群中所有可用设备作为 osd
```shell
ceph orch apply osd --all-available-devices
```