


# 部署openstack
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
# 注意--mon-ip修改为本机IP
./cephadm bootstrap --mon-ip 192.168.224.111 --allow-fqdn-hostname --skip-monitoring-stack --skip-dashboard
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

# 将‘# rule’下第6行的`host`改为`osd`
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
scp root@192.168.224.111:/etc/ceph/ceph.client.zhangmingming.keyring /etc/ceph/
scp root@192.168.224.111:/etc/ceph/ceph.conf /etc/ceph/
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
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Step 4: 开启Docker服务
service docker start
```
### 安装docker-compose
```shell
wget https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker compose version
```
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
192.168.224.21 master1
192.168.224.22 master2
192.168.224.23 master3
192.168.224.24 node1
192.168.224.25 node2
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
server master1 iburst
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
![[100.附件/cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm]]

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
vim /etc/keepalived/keepalived.conf

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

master3配置
[root@master3 ~]# vim /etc/keepalived/keepalived.conf

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
    interface ens33
    mcast_src_ip 192.168.1.23
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.1.88
    }
#    track_script {
#       chk_apiserver
#    }
}
三个master节点配置心跳检测脚本
vim /etc/keepalived/check_apiserver.sh
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

[root@master1 ~]# chmod +x /etc/keepalived/check_apiserver.sh
[root@master1 ~]# systemctl restart keepalived

#配置haproxy
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
vim /etc/haproxy/haproxy.cfg

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
  server master1  192.168.1.21:6443  check
  server master2  192.168.1.22:6443  check
  server master3  192.168.1.23:6443  check
  
[root@master1 ~]# systemctl enable --now haproxy.service

```



# mysql部署


# mysql对接ceph

# discuz容器发布

# prometheus



