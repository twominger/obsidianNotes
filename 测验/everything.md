
[[测验/创建自定义镜像]]
# 部署openstack
[[#部署openstack]]
网卡最好用桥接模式
桥接无法代理问题解决
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250403024236405.png)
运行如下命令即可（ip为宿主机ip）：
```shell
export http_proxy=192.168.224.144:7897
export https_proxy=192.168.224.144:7897
# 依然无法ping通外网，但是其他一切正常，可以拉取外网镜像
```
取消：
```shell
unset http_proxy
unset https_proxy
```
openstack实例需要有浮动ip
# 部署单节点ceph(两台)
在osp的物理机上为cs01和cs02两台机器配置两套P版16.2.11的单节点ceph集群，每套集群可以使用9个OSD，无需部署dashboard和监控相关组件，仅部署mon和mgr以及OSD和相关必要组件，通过172.17.0.1的mon可以访问并使用cs01的集群，通过172.17.0.2的mon可以访问到第二套集群，其中cs01的集群为生产集群，cs02为灾备集群
## 部署流程
- vmware虚拟机准备，两台，NAT，除系统盘外再加9块硬盘
- 安装必要组件
```shell
yum -y install python3
yum -y install lvm2
yum -y install podman
```
- 配置时间同步
```shell
timedatectl set-timezone Asia/Shanghai
# osp
cat >/etc/chrony.conf <<EOF
pool ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 172.18.0.0/24
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd
chronyc sources

# cs01\cs02
cat >/etc/chrony.conf <<EOF
pool 192.168.10.10 iburst
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
- 下载cephadm脚本并安装
```shell
# 下载
wget http://lab4.cn/cephadm
# 添加存储库
chmod +x ./cephadm
./cephadm add-repo --release pacific
# 安装cephadm
./cephadm install
```
- 引导ceph集群
```shell
# cs01
./cephadm bootstrap --mon-ip 172.18.0.10 --allow-fqdn-hostname --skip-monitoring-stack --skip-dashboard
# cs02
./cephadm bootstrap --mon-ip 172.18.0.20 --allow-fqdn-hostname --skip-monitoring-stack --skip-dashboard
```
>[!tip]
>`--allow-fqdn-hostname` 允许使用主机名进行节点识别
>`--skip-monitoring-stack` 跳过 Ceph 集群的监控栈部署
>`--skip-dashboard` 跳过 **Ceph Dashboard** 部署

- 安装ceph的客户端软件
```shell
yum -y install ceph-common
```
- 添加osd
```shell
ceph orch apply osd --all-available-devices
```
- 修改故障域为OSD
```shell
# 进入ceph集群管理容器
cephadm shell
ceph osd getcrushmap >> crushmap.bin
crushtool -d crushmap.bin >> crushmap.txt
vi crushmap.txt

# 将‘# rule’下第7行的`host`改为`osd`
rule replicated_rule {
        id 0
        type replicated
        min_size 1
        max_size 10
        step take default
        step chooseleaf firstn 0 type osd
        step emit
}

rm -f crushmap.bin
crushtool -c crushmap.txt -o crushmap.bin
ceph osd setcrushmap -i crushmap.bin
```
## 使用前准备
### 创建rbd存储池及用户
在cs01为ops和Mysql分别配置名为cinder-pool和mysql-pool的存储池，存储池使用RBD类型的存储，存储空间分别配置10GB大小，使用3副本保障数据的安全性，并创建用于对接ceph存储中RBD连接的普通用户，用户名设置为你姓名全拼的用户（例如：姓名张三，账号设置：zhangsan），对cinder-pool和 mysql-pool 存储池具有读写权限。
```shell
# 创建存储池
ceph osd pool create cinder-pool
ceph osd pool create mysql-pool
# 创建标签
ceph osd pool application enable cinder-pool rbd
ceph osd pool application enable mysql-pool rbd
# 添加用户
ceph auth add client.zhangmingming mon 'allow r' osd 'allow rwx'
# 创建mysql的rbd映像
rbd create mysql-pool/mysql-data --size 10G
rbd create mysql-pool/mysql-data2 --size 10G
rbd create mysql-pool/mysql-data3 --size 10G
```
### 创建cephFS存储池并添加用户权限
在cs01为Kubernetes配置一个名为kubernetes-pool的存储池，该存储池使用CephFS类型的存储配置一个k8s_fs的文件系统存储，使用3副本保障数据的安全性，并创建用于对接ceph存储中CephFS连接的普通用户，用户名设置为你姓名全拼的用户（例如：姓名张三，账号设置：zhangsan），对kubernetes-pool存储池的具有读写权限。
```shell
# 创建数据池
ceph osd pool create kubernetes-data
# 创建元数据池
ceph osd pool create kubernetes-metadata
# 数据池配置cephfs类型
ceph osd pool application enable kubernetes-data cephfs
ceph osd pool application enable kubernetes-metadata cephfs
# 构建一个名为k8s_fs的文件系统，使用kubernetes-metadata作为元数据池，使用kubernetes-data作为数据池
ceph fs new k8s_fs kubernetes-metadata kubernetes-data
# 修改用户的权限，增加对mds的读写权限
ceph auth caps client.zhangmingming mon "allow r" osd "allow rwx" mds "allow rw" mgr "allow rw"
# 部署一个MDS
ceph orch apply mds k8s_fs --placement=1
```
### 云硬盘容灾
为OpenStack配置云硬盘多站点容灾，将CS01生产站点中的cinder_pool存储池中的RBD通过RBD镜像Mirror的方式同步到远程灾备站点CS02，同步的模式为单向模式，镜像复制方式为池模式
```shell
# CS01集群操作:
rbd mirror pool enable cinder-pool pool # 开启存储池同步，同步模式为池模式
rbd mirror pool peer bootstrap create --site-name cs01 cinder-pool > /opt/cs01.key # 创建集群秘钥并导出
scp /opt/cs01.key root@cs02:/opt/ # 发送key到cs02的灾备集群
rbd feature enable cinder-pool/volume-27147c92-e11b-4c52-8bba-af82088ada58 journaling # 开启目标RBD同步特性

# CS02集群操作:
ceph osd pool create cinder-pool # 创建存储池和主集群相同
ceph osd pool application enable cinder-pool rbd # 为存储池创建标签
ceph orch apply rbd-mirror --placement=1 # 安装rbd-mirror
rbd mirror pool peer bootstrap import --site-name cs02 --direction rx-only cinder-pool /opt/cs01.key # 导入cs01的集群秘钥
rbd -p cinder-pool ls # 查看存储池卷是否同步
```
### 其他
2.5 随着业务的使用量增加，mysql所使用的rbd镜像需要进行扩容到20G大小
```shell
rbd resize mysql-pool/mysql-data --size 20G
xfs_growfs /data/mysql/data
```
2.6 运维工程师为了调整云硬盘中操作系统的数据，决定对cinder中的k8s-image镜像进行改造，使用rbd克隆技术得到克隆卷k8s-clone并将克隆的镜像挂载起来，删除镜像中k8s的配置文件，然后将其导出到，灾备站点的backup-pool的存储池中，命名为k8s-image-backup
```shell
# 创建快照
rbd snap create cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01

# 保护快照（必需步骤）
rbd snap protect cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01

# 创建克隆卷
rbd clone cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01 cinder-pool/k8s-clone

扁平化克隆卷（独立于源卷）
rbd flatten cinder-pool/k8s-clone

# 映射设备
rbd map cinder-pool/k8s-clone --id zhangsan --keyring /etc/ceph/ceph.client.zhangsan.keyring

# 创建挂载点并挂载（假设文件系统为 ext4）
mkdir /mnt/k8s-clone
mount /dev/rbd0 /mnt/k8s-clone

rm -rf /mnt/k8s-clone/etc/kubernetes/*

卸载并取消映射
umount /mnt/k8s-clone
rbd unmap /dev/rbd0
   
scp /etc/ceph/*  root@osp:/opt/ #将第一套集群的配置上传到osp节点

rbd export  cinder-pool/k8s-clone  k8s-clone.img -c ceph.conf --keyring  ceph.client.admin.keyring #导出成为文件
rm -rf /opt/ceph*
scp /etc/ceph/*  root@osp:/opt/ #将第二套集群的配置上传到osp节点

#容灾站点操作
ceph osd  pool  create  backup-pool #创建备份池
ceph osd  pool  application  enable  backup-pool rbd #打标签

#镜像所在节点
rbd import /opt/k8s-clone.img  backup-pool/k8s-image-backup  -c /opt/ceph.conf --keyring /opt/ceph.client.admin.keyring

```
# cinder对接ceph
## ceph节点操作
```shell
# 导出cinder密钥
ceph auth get client.zhangmingming -o /etc/ceph/ceph.client.zhangmingming.keyring
```
## openstack操作
### 所有节点
```shell
# 创建ceph配置文件目录
mkdir /etc/ceph/
# 拷贝密钥和配置文件
scp root@172.18.0.10:/etc/ceph/ceph.client.zhangmingming.keyring /etc/ceph/
scp root@172.18.0.10:/etc/ceph/ceph.conf /etc/ceph/
```
### 所有计算节点
```shell
# 添加libvirt密钥
# 生成密钥（PS：注意，如果有多个计算节点，它们的UUID必须一致）
cd /etc/ceph/

UUID=$(uuidgen)
cat >> secret.xml << EOF
<secret ephemeral='no' private='no'>
  <uuid>$UUID</uuid>
  <usage type='ceph'>
    <name>client.zhangmingming secret</name>
  </usage>
</secret>
EOF

# 执行命令写入secret
virsh secret-define --file secret.xml

# 查看添加后端密钥(记录下来)
 virsh secret-list
 UUID                                   Usage
-------------------------------------------------------------------
 bf168fa8-8d5b-4991-ba4c-12ae622a98b1   ceph client.zhangmingming secret

# 加入key
# 将key值复制出来
cat ceph.client.zhangmingming.keyring
AQCvztRk8ssALhAAXshR1E+Y90HvIyxkhal1cQ==

virsh secret-set-value --secret ${UUID} --base64 $(cat ceph.client.zhangmingming.keyring | grep key | awk -F ' ' '{print $3}')
```
### 控制节点
```shell
# 主要作用是OpenStack可调用Ceph资源
yum install -y ceph-common

#配置cinder后端存储
chown cinder.cinder /etc/ceph/ceph.client.zhangmingming.keyring

#修改cinder配置文件
vim /etc/cinder/cinder.conf

# 注意修改rbd_secret_uuid字段
enabled_backends = lvm,ceph

[ceph]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_pool = cinder-pool
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
glance_api_version = 2
rbd_user = zhangmingming
rbd_secret_uuid = bf168fa8-8d5b-4991-ba4c-12ae622a98b1
volume_backend_name = ceph

# 创建卷类型
source ~/keystonerc_admin
openstack volume type create ceph

# 设置卷类型元数据
cinder --os-username admin --os-tenant-name admin type-key ceph set volume_backend_name=ceph

# 查看存储类型
openstack volume type list
+--------------------------------------+-------------+-----------+
| ID                                   | Name        | Is Public |
+--------------------------------------+-------------+-----------+
| ccb0cd1e-562a-42e0-b0d0-3818d6910528 | ceph        | True      |
| 5ffdbebe-4f37-4690-8b40-36c6e6c63233 | lvm         | True      |
| c5b71526-643d-4e9c-b0b7-3cdf8d1e926b | __DEFAULT__ | True      |
+--------------------------------------+-------------+-----------+
#查看到存储类型后重启服务
systemctl restart openstack-cinder-scheduler.service openstack-cinder-volume.service

# 创建卷测试
openstack volume create ceph01 --type ceph --size 1
# 查看volumes存储池是否存在卷
rbd ls volumes
```
# harbor镜像仓库
## 创建harbor镜像仓库
### 安装docker
```shell
# step 1: 安装必要的一些系统工具
yum install -y yum-utils
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 安装Docker
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Step 4: 开启Docker服务
service docker start
systemctl enable docker --now
```
### 安装docker-compose
```shell
wget https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker compose version
```
![[附件/docker-compose-linux-x86_64|docker-compose-linux-x86_64]]
### http协议搭建
```shell
mkdir -p /data/harbordata/
wget https://github.com/goharbor/harbor/releases/download/v2.11.1/harbor-offline-installer-v2.11.1.tgz
tar -zxvf harbor-offline-installer-v2.11.1.tgz -C /usr/local/
cd /usr/local/harbor
```
修改配置文件
```shell
#拷贝harbor的模板配置文件，新文件名字叫harbor.yml
cp harbor.yml.tmpl harbor.yml
#编辑harbor.yml配置文件
vim harbor.yml

hostname: hub.lib0.cn # 此处的主机名换成本机的ip地址、如果使用域名要与ip地址进行绑定(/etc/hosts)
http:
  port: 80  # 默认监听80端口

# https related config
#https:
  # https port for harbor, default is 443
  #port: 443
  # The path of cert and key files for nginx
  #certificate: /your/certificate/path
  #private_key: /your/private/key/path
  # enable strong ssl ciphers (default: false)
  # strong_ssl_ciphers: false

harbor_admin_password: redhat  harbor的密码

data_volume:/data/harbordata/  # 数据存储目录，推荐放在一个单独的目录
```
添加域名解析
```shell
cat > /etc/hosts <<EOF
192.168.224.188 hub.lib0.cn
EOF
```
修改daemon.json文件
```shell
cat >/etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [ "https://e9ede121ca7d4163b95042f86b165fa4.mirror.swr.myhuaweicloud.com" ],
    "insecure-registries": ["http://192.168.224.188","hub.lib0.cn"]
}
EOF
```
重启docker
```shell
systemctl restart docker
```
安装harbor
```shell
[root@harbor harbor]# pwd
/usr/local/harbor

./install.sh
```
## 基本使用
- 图形界面创建项目discuz
- 推送镜像
```shell
# 登陆镜像仓库
docker login http://192.168.224.188
# 提交镜像到镜像仓库
docker images
docker tag nginx 192.168.224.188/discuz/nginx:v1
docker push 192.168.224.188/discuz/nginx:v1
```
- 拉取镜像(其他主机)

```shell
cat >/etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [ "https://e9ede121ca7d4163b95042f86b165fa4.mirror.swr.myhuaweicloud.com" ],
    "insecure-registries": ["http://192.168.224.188","hub.lib0.cn"]
}
EOF

systemctl restart docker


docker login http://192.168.224.188
docker pull 192.168.224.188/discuz/nginx:v1
docker images
```
# k8s集群搭建

初始化

```shell
cat >>/etc/hosts <<EOF
192.168.224.21 m01
192.168.224.22 m02
192.168.224.23 m03
192.168.224.24 n01
192.168.224.25 n02
EOF
```

```shell
# master01
yum -y install chrony
cat >/etc/chrony.conf <<EOF
server ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.224.0/24
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources

# master02\master03\node01\node02
yum -y install chrony
cat >/etc/chrony.conf <<EOF
server m01 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```

```shell
sed -ri 's/.*swap.*/#&/g' /etc/fstab
swapoff -a
```

```shell
cat > /etc/sysctl.d/k8s_better.conf << EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF

modprobe br_netfilter
modprobe ip_conntrack
lsmod |grep conntrack

sysctl -p /etc/sysctl.d/k8s_better.conf


cat /sys/class/dmi/id/product_uuid
# 确保每台服务器的uuid不一致、如果是克隆机器、修改网卡配置文件删除uuid那一行
```

```shell
yum install -y net-tools conntrack ipvsadm ipset iptables curl sysstat libseccomp wget

modprobe br_netfilter

cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules 
bash /etc/sysconfig/modules/ipvs.modules 
lsmod | grep -e ip_vs -e nf_conntrack

# ip_vs_sh               12688  0 
# ip_vs_wrr              12697  0 
# ip_vs_rr               12600  0 
# ip_vs                 145458  6 ip_vs_rr,ip_vs_sh,ip_vs_wrr
# nf_conntrack_ipv4      15053  0 
# nf_defrag_ipv4         12729  1 nf_conntrack_ipv4
# nf_conntrack          139264  2 ip_vs,nf_conntrack_ipv4
# libcrc32c              12644  3 xfs,ip_vs,nf_conntrack
```


```shell
# step 1: 安装必要的一些系统工具
yum install -y yum-utils
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 安装Docker
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Step 4: 开启Docker服务
systemctl enable docker --now
```

```shell
#修改cgroup
cat > /etc/docker/daemon.json << EOF

  {
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://hub.mirrorify.net",
    "https://docker.m.daocloud.io",
    "https://registry.dockermirror.com",
    "https://docker.aityp.com/",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.icu",
    "https://docker.awsl9527.cn"
  ],
 "insecure-registries":["https://harbor.flyfish.com"],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
    },
  "data-root": "/var/lib/docker"
}
EOF

```

```shell
# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.6/cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm
yum -y install cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm

sed -i 's|ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd://|ExecStart=/usr/bin/cri-dockerd --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.9 --container-runtime-endpoint fd://|' /usr/lib/systemd/system/cri-docker.service

systemctl enable cri-docker --now
```
![[附件/cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm]]

```shell
# 添加K8s阿里源
cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/repodata/repomd.xml.key
EOF

yum clean all
yum makecache
# yum list kubelet --showduplicates | sort -r | grep 1.31
yum install -y kubectl-1.31.7 kubelet-1.31.7 kubeadm-1.31.7

systemctl enable kubelet --now
# kubeadm config images list --kubernetes-version=v1.31.7

kubeadm config images pull --kubernetes-version=v1.31.7 --image-repository registry.aliyuncs.com/google_containers --cri-socket unix:///run/cri-dockerd.sock

#查看镜像是否拉取成功
docker images
```
以上步骤制作 k8s-img 镜像

- 高可用
```shell
yum install -y keepalived haproxy 
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
# master1配置
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
    script_user root
    enable_script_security
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state MASTER
    interface ens160
    mcast_src_ip 192.168.224.21
    virtual_router_id 51
    priority 102
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.224.88
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# master2配置
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
    script_user root
    enable_script_security
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    mcast_src_ip 192.168.224.22
    virtual_router_id 51
    priority 101
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.224.88
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# master3配置
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
    script_user root
    enable_script_security
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 5
    weight -5
    fall 2
    rise 1
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    mcast_src_ip 192.168.224.23
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.224.88
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# 三个master节点配置心跳检测脚本
cat >/etc/keepalived/check_apiserver.sh <<EOF
#!/bin/bash

err=0
for k in $(seq 1 3)
do
    check_code=$(pgrep haproxy)
    if [[ $check_code == "" ]]; then
        err=$(expr $err + 1)
        sleep 1
        continue
    else
        err=0
        break
    fi
done

if [[ $err != "0" ]]; then
    echo "systemctl stop keepalived"
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi
EOF

chmod +x /etc/keepalived/check_apiserver.sh
systemctl enable keepalived
systemctl restart keepalived

#配置haproxy
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
cat >/etc/haproxy/haproxy.cfg <<EOF

global
  maxconn  2000
  ulimit-n  16384
  log  127.0.0.1 local0 err
  stats timeout 30s

defaults
  log global
  mode  http
  option  httplog
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  timeout http-request 15s
  timeout http-keep-alive 15s

frontend monitor-in
  bind *:33305
  mode http
  option httplog
  monitor-uri /monitor

frontend k8s-master
  bind 0.0.0.0:16443
  bind 127.0.0.1:16443
  mode tcp
  option tcplog
  tcp-request inspect-delay 5s
  default_backend k8s-master

backend k8s-master
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server master1  192.168.224.21:6443  check
  server master2  192.168.224.22:6443  check
  server master3  192.168.224.23:6443  check
EOF
  
systemctl enable --now haproxy.service

sed -i '/#.*track_script {/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*chk_apiserver/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*}/ s/^#//' /etc/keepalived/keepalived.conf

systemctl restart keepalived
```

```shell
# 在master1节点操作
kubeadm init --control-plane-endpoint=192.168.224.88:16443 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.31.7 --service-cidr=10.96.0.0/16 --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock

# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# You can now join any number of control-plane nodes by copying certificate authorities
# and service account keys on each node and then running the following as root:

# kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
#     --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c \
#     --control-plane 

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
#     --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c 

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
scp -r /etc/kubernetes/pki root@master2:/etc/kubernetes/
scp -r /etc/kubernetes/pki root@master3:/etc/kubernetes/
```

```shell
# master2\3加入集群
cd /etc/kubernetes/pki/
rm -rf apiserver*
rm -rf etcd/peer.*
rm -rf etcd/server.*
kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
    --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c \
    --control-plane \
    --cri-socket unix:///var/run/cri-dockerd.sock
    
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# node1\2加入集群
kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
    --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c \
    --cri-socket unix:///var/run/cri-dockerd.sock
```

```shell
wget https://docs.tigera.io/archive/v3.25/manifests/calico.yaml

vim calico.yaml
# no effect. This should fall within `--cluster-cidr`.
            - name: CALICO_IPV4POOL_CIDR
              value: "10.244.0.0/16"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens160"

```
![[附件/calico.yaml]]
# discuz 容器镜像制作
测试环境:
```shell
yum install -y php php-fpm
yum -y install nginx
# 配置/etc/nginx/nginx.conf
git clone https://gitee.com/Discuz/DiscuzX.git
cd /root/DiscuzX/upload
sed -i '1394s/.*/PRIMARY KEY (daytime)/'  install/data/install.sql
sed -i '2691s/.*/  groupid smallint(6) unsigned NOT NULL DEFAULT '0' KEY,/'  install/data/install.sql
sed -i '404s/.*/ PRIMARY KEY (logid)/g' install/data/install.sql
sed -i "s/\$nowdaytime = dgmdate(TIMESTAMP, 'Ymd');/\$nowdaytime = dgmdate(TIMESTAMP, 'YmdHis');/" ./source/class/table/table_common_stat.php

cp -a /root/Discuz/upload/* /usr/share/nginx/html/
chmod -R 777 /usr/share/nginx/html/

yum install -y php-mysqli php-xml
```
- nginx. conf
```shell
cat >nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;
        index index.php index.html index.htm

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location ~ .php$ {
            #fastcgi_pass unix:/var/run/php-fpm/www.sock;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF
```
- Dockerfile
```shell
cat >Dockerfile <<EOF
FROM php:7.2-fpm
  
RUN apt-get update && \
    useradd -r -s /sbin/nologin nginx && \
    apt-get install -y nginx libldap2-dev && \
    docker-php-ext-install pdo pdo_mysql && \
    docker-php-ext-install mysqli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/nginx/html

COPY nginx.conf /etc/nginx/
COPY upload /usr/share/nginx/html/
RUN chmod -R 777 *

EXPOSE 80

CMD ["sh", "-c", "nginx -g 'daemon off;' & php-fpm -F"]
EOF
```
封装、测试
```shell
docker build -t nginx-discuz:v1 .
docker run -d -p 80:80 --add-host mysql:192.168.44.41 nginx-discuz:v1
```
推送（以阿里为例）
```shell
# 登陆
docker login --username=aliyun0025329374 crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com
Han@201314
# 拉取
docker pull crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx-discuz:[镜像版本号]
# 推送
docker login --username=aliyun0025329374 crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com
docker tag [ImageId] crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx-discuz:[镜像版本号]
docker push crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx-discuz:[镜像版本号]
```
# k8s 对接 cephfs
pod 使用 ceph 存储
https://www.wolai.com/chuangxinyang/2yQcF1mDBJ3GYMzZrEy58L
# mysql部署
```shell
mkdir /etc/ceph
scp root@192.168.224.111:/etc/ceph/ceph.client.zhangmingming.keyring /etc/ceph/
scp root@192.168.224.111:/etc/ceph/ceph.conf /etc/ceph/
sshpass -p 'redhat' scp root@192.168.224.111:/etc/ceph/ceph.client.admin.keyring /etc/ceph/

yum install ceph ceph-common librados2 librgw-devel librados-devel.x86_64 -y
rbd map mysql-data --pool mysql-pool --id zhangmingming
mkfs.ext4 /dev/rbd0
mkdir -p /data/mysql
mount /dev/rbd0 /data/mysql
```

```shell
tar -xvf ~/mysql-8.0.41-linux-glibc2.28-x86_64.tar.xz -C /usr/local/
ln -s /usr/local/mysql-8.0.41-linux-glibc2.28-x86_64 /usr/local/mysql
echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile
source /etc/profile
useradd -r -s /sbin/nologin mysql
mkdir -p /data/mysql/{data,log}
chown -R mysql:mysql /usr/local/mysql/
chown -R mysql:mysql /data/mysql/
cat >/etc/my.cnf <<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/mysql/data
port=3306
socket=/tmp/mysql.sock
symbolic-links=0
character-set-server=utf8
log-error=/data/mysql/log/mysqld.log
pid-file=/usr/local/mysql/mysqld.pid
EOF
mysqld --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
systemctl enable mysqld
systemctl restart mysqld
systemctl status mysqld

mysqladmin -u root password "yutian"

```

- keepalived+haproxy
- discuz k8s 部署
- 备份机制
https://www.wolai.com/chuangxinyang/wGgUnf6udDBbCqkHTBBvVc
- 改密码
4.3 工程师张三在操作时丢失了Discuz平台的管理员用户admin的密码，需要将其重置为 yutian@123 。（Discuz用户存储在pre_ucenter_members表中）
  - 解题思路：
      - 查看pre_ucenter_members表中张三用户信息
      - 重新创建一个lisi用户密码设置为yutian@123
      - 再此查看pre_ucenter_members表信息
      - 复制lisi用户password字段加密后的密码
      - 使用update语句更改pre_ucenter_members表中张三用户的password字段为lisi用户password字段一致。
      - 在此尝试张三用户密码是否更改成功
# prometheus
[[10.课件/OpenStack课堂笔记-田/20250222-k8s-用户角色权限及helm介绍#helm|20250222-k8s-用户角色权限及helm介绍]]
安装 prometheus
![[附件/get_helm.sh]]
```shell
# 安装helm工具包
export http_proxy=192.168.224.144:7897
export https_proxy=192.168.224.144:7897
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
# 拉取helm仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 创建命名空间
kubectl create namespace monitoring

/etc/docker/daemon.json
"proxies": {
    "http-proxy": "192.168.224.144:7897",
    "https-proxy": "192.168.224.144:7897"
  },
systemctl restart docker

# 安装promethues
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=31000 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=31001
  
# 修改完成查看映射端口号登录网页测试grafana
kubectl  get svc -n monitoring
192.168.224.21：31001

# 查看默认登录用户和密码
kubectl get secrets -n monitoring
kubectl describe secrets prometheus-stack-grafana -n monitoring
kubectl edit secrets prometheus-stack-grafana -n monitoring

data:
  admin-password: cHJvbS1vcGVyYXRvcg==
  admin-user: YWRtaW4=

# 通过base64编码反推
# 默认用户admin
echo "YWRtaW4=" | base64 --decode
admin

# 默认admin密码
echo "cHJvbS1vcGVyYXRvcg==" | base64 --decode
prom-operator

#第二种查看用户、密码方法
kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-user}" | base64 -d ; echo
kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
## prometheus 监控 mysql
https://www.wolai.com/chuangxinyang/37Ub1yhJ85vPMZCSwxpBm7
```shell

```
## prometheus 监控 ceph
https://www.wolai.com/chuangxinyang/37Ub1yhJ85vPMZCSwxpBm7
## prometheus 监控 openstack
https://www.wolai.com/chuangxinyang/2yQcF1mDBJ3GYMzZrEy58L



discuz 镜像问题

calico 经常失效问题

k8s 拉取 http 镜像

```shell
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  2m27s                default-scheduler  Successfully assigned discuz/discuz-deployment-fb7b47979-jtbc7 to n01
  Warning  Failed     63s (x3 over 2m12s)  kubelet            Failed to pull image "hub.lab0.cn/discuz/nginx-discuz:v1": Error response from daemon: Get "https://hub.lab0.cn/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
  Warning  Failed     63s (x3 over 2m12s)  kubelet            Error: ErrImagePull
  Normal   BackOff    26s (x5 over 2m11s)  kubelet            Back-off pulling image "hub.lab0.cn/discuz/nginx-discuz:v1"
  Warning  Failed     26s (x5 over 2m11s)  kubelet            Error: ImagePullBackOff
  Normal   Pulling    12s (x4 over 2m27s)  kubelet            Pulling image "hub.lab0.cn/discuz/nginx-discuz:v1"


```

- sql01
```shell
cat >>/etc/my.cnf <<EOF
server_id=1      #id号要唯一
gtid_mode=ON
enforce_gtid_consistency=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog_checksum=NONE
log_slave_updates=ON
log_bin=binlog
binlog_format=ROW
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name='ce9be252-2b71-11e6-b8f4-00212844f856'
loose-group_replication_start_on_boot=off
loose-group_replication_local_address='sql01:33061'
loose-group_replication_group_seeds='sql01:33061,sql02:33061,sql03:33061'
loose-group_replication_bootstrap_group=off
EOF

# 进入mysql
mysql -uroot -pyutian

set sql_log_bin=0;
CREATE USER 'admin'@'172.17.10.%' IDENTIFIED BY 'yutian';
GRANT REPLICATION SLAVE ON *.* TO 'admin'@'172.17.10.%';
flush privileges;
set sql_log_bin=1;

#构建group replication集群
change master to master_user='admin',master_password='yutian'  for channel 'group_replication_recovery';

install plugin group_replication soname 'group_replication.so';

set global group_replication_bootstrap_group=on;

start group_replication;

set global group_replication_bootstrap_group=OFF;

```

sql02\03
```shell
# sql02
cat >>/etc/my.cnf <<EOF
server_id=2      #id号要唯一
gtid_mode=ON
enforce_gtid_consistency=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog_checksum=NONE
log_slave_updates=ON
log_bin=binlog
binlog_format=ROW
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name='ce9be252-2b71-11e6-b8f4-00212844f856'
loose-group_replication_start_on_boot=off
loose-group_replication_local_address='sql02:33061'
loose-group_replication_group_seeds='sql01:33061,sql02:33061,sql03:33061'
loose-group_replication_bootstrap_group=off
#loose-group_replication_single_primary_mode = off
#loose-group_replication_enforce_update_everywhere_checks = on
EOF
# sql03
cat >>/etc/my.cnf <<EOF
server_id=3      #id号要唯一
gtid_mode=ON
enforce_gtid_consistency=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog_checksum=NONE
log_slave_updates=ON
log_bin=binlog
binlog_format=ROW
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name='ce9be252-2b71-11e6-b8f4-00212844f856'
loose-group_replication_start_on_boot=off
loose-group_replication_local_address='sql03:33061'
loose-group_replication_group_seeds='sql01:33061,sql02:33061,sql03:33061'
loose-group_replication_bootstrap_group=off
#loose-group_replication_single_primary_mode = off
#loose-group_replication_enforce_update_everywhere_checks = on
EOF

set sql_log_bin=0;
CREATE USER 'admin'@'172.17.10.%' IDENTIFIED BY 'yutian';
GRANT REPLICATION SLAVE ON *.* TO 'admin'@'172.17.10.%';
flush privileges;
set sql_log_bin=0;

change master to master_user='admin',master_password='yutian'  for channel 'group_replication_recovery';

install plugin group_replication soname 'group_replication.so';

set global group_replication_allow_local_disjoint_gtids_join=ON;

start group_replication;
```

- 查看复制组状态
```shell
select * from performance_schema.replication_group_members;
```