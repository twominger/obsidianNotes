# 环境
- 宿主机环境：

|        |                                                        |
| ------ | ------------------------------------------------------ |
| 处理器    | Intel (R) Core (TM) i7-10750H CPU @ 2.60GHz   2.59 GHz |
| 机带 RAM | 32.0 GB (31.9 GB 可用)                                   |
| 操作系统   | Windows 11 家庭中文版 24H2                                  |
| 系统类型   | 64 位操作系统, 基于 x64 的处理器                                  |
| 外部网络   | 192.168.224.144 （网关为 192.168.224.8）                    |
- vmware 版本：VMware® Workstation 17 Pro 17.0.0 build-20800274
- OpenStack 环境：

| 节点         | 网络                   | CPU | 内存  | 硬盘   |
| ---------- | -------------------- | --- | --- | ---- |
| controller | 192.168.224.100 (桥接) | 4   | 8G  | 100G |
| compute1   | 192.168.224.101      | 4   | 10G | 100G |
| compute2   | 192.168.224.102      | 4   | 8G  | 100G |
- ceph 环境

| 节点   | 网络                   | CPU | 内存  | 硬盘         |
| ---- | -------------------- | --- | --- | ---------- |
| cs01 | 192.168.224.111 (桥接) | 2   | 4G  | 100G+30G*9 |
| cs02 | 192.168.224.112 (桥接) | 2   | 4G  | 100G+30G*9 |
- 网络

| 实例名称   | 网络  | 规格    |
| ------ | --- | ----- |
| sql01  |     | 1C/2G |
| sql02  |     | 1C/2G |
| sql03  |     | 1C/2G |
| harbor |     | 1C/2G |
| m01    |     | 1C/2G |
| m02    |     | 1C/2G |
| m03    |     | 1C/2G |
| n01    |     | 1C/2G |
| n02    |     | 2C4G  |
| discuz |     | 1C1G  |

# 创建自定义镜像
[[测验/创建自定义镜像|创建自定义镜像]]
# 部署 openstack
[[#部署openstack]]
网卡最好使用桥接模式
桥接无法代理问题解决
# 部署两台单节点 ceph 
在 osp 的物理机上为 cs01 和 cs02 两台机器配置两套 P 版 16.2.11 的单节点 ceph 集群，每套集群可以使用 9 个 OSD，无需部署 dashboard 和监控相关组件，仅部署 mon 和 mgr 以及 OSD 和相关必要组件，通过 172.17.0.1 的 mon 可以访问并使用 cs01 的集群，通过 172.17.0.2 的 mon 可以访问到第二套集群，其中 cs01 的集群为生产集群，cs02 为灾备集群
## 部署流程 (cs01 && cs02)
### 准备 vmware虚拟机
- vmware 克隆两台虚拟机，除系统盘外再加 9 块硬盘，单张网卡改桥接，初始化
### 安装必要组件
```shell
yum -y install python3
yum -y install lvm2
yum -y install podman
```
### 配置时间同步
原则上 ceph 集群以及数据库不能访问外网，所以只能同步内部时间服务器，这里我们将 openstack 的控制节点作为时间服务器，其他计算节点和 ceph 都同步它。
- controller
```shell
timedatectl set-timezone Asia/Shanghai

cat >/etc/chrony.conf <<EOF
pool ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.224.0/24
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd
chronyc sources
```
- cs01\cs02
```shell
timedatectl set-timezone Asia/Shanghai

cat >/etc/chrony.conf <<EOF
pool 192.168.224.100 iburst
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
### 下载 cephadm 脚本并安装
```shell
# 下载
wget http://lab4.cn/cephadm
# 添加执行权限
chmod +x ./cephadm
# 添加存储库
./cephadm add-repo --release pacific
# 安装cephadm
./cephadm install
```
### 引导 ceph 集群
```shell
# cs01
./cephadm bootstrap --mon-ip 172.18.0.10 --allow-fqdn-hostname --skip-monitoring-stack --skip-dashboard
# cs02
./cephadm bootstrap --mon-ip 172.18.0.20 --allow-fqdn-hostname --skip-monitoring-stack --skip-dashboard
```
### 安装 ceph 的客户端软件
```shell
yum -y install ceph-common
```
### 添加 osd
```shell
ceph orch apply osd --all-available-devices
```
### 修改故障域为 OSD
> [!tip]
> 一定要等到 `osd: 9 osds: 9 up , 9 in ` 之后再修改故障域
> 
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
## ceph使用前准备
### 创建 rbd 存储池及用户（仅 cs01）
在 cs01 为 ops 和 Mysql 分别配置名为 cinder-pool 和 mysql-pool 的存储池，存储池使用 RBD 类型的存储，存储空间分别配置 10GB 大小，使用 3 副本保障数据的安全性，并创建用于对接 ceph 存储中 RBD 连接的普通用户，用户名设置为你姓名全拼的用户（例如：姓名张三，账号设置：zhangsan），对 cinder-pool 和 mysql-pool 存储池具有读写权限。
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
rbd create mysql-pool/mysql-data1 --size 10G
rbd create mysql-pool/mysql-data2 --size 10G
rbd create mysql-pool/mysql-data3 --size 10G
```
### 创建 cephFS 存储池并添加用户权限（仅 cs01）
在 cs01 为 Kubernetes 配置一个名为 kubernetes-pool 的存储池，该存储池使用 CephFS 类型的存储配置一个 k8s_fs 的文件系统存储，使用 3 副本保障数据的安全性，并创建用于对接 ceph 存储中 CephFS 连接的普通用户，用户名设置为你姓名全拼的用户（例如：姓名张三，账号设置：zhangsan），对 kubernetes-pool 存储池的具有读写权限。
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
### 云硬盘容灾（等到 openstack 创建卷之后针对卷进行备份）(cs01 && cs02)
为 OpenStack 配置云硬盘多站点容灾，将 CS01 生产站点中的 cinder_pool 存储池中的 RBD 通过 RBD 镜像 Mirror 的方式同步到远程灾备站点 CS02，同步的模式为单向模式，镜像复制方式为池模式
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
### mysql 扩容（放在后面做）
随着业务的使用量增加，mysql 所使用的 rbd 镜像需要进行扩容到 20G 大小
```shell
rbd resize mysql-pool/mysql-data --size 20G
xfs_growfs /data/mysql/data
```
### rbd 卷改造 (放后面做)
运维工程师为了调整云硬盘中操作系统的数据，决定对 cinder 中的 k8s-image 镜像进行改造，使用 rbd 克隆技术得到克隆卷 k8s-clone 并将克隆的镜像挂载起来，删除镜像中 k8s 的配置文件，然后将其导出到，灾备站点的 backup-pool 的存储池中，命名为 k8s-image-backup
```shell
# 创建快照
rbd snap create cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01

# 保护快照（必需步骤）
rbd snap protect cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01

# 创建克隆卷
rbd clone cinder-pool/volume-6ce9b8a7-b78f-4429-96f0-0fd4303fba5d@snap01 cinder-pool/k8s-clone

# 扁平化克隆卷（独立于源卷）
rbd flatten cinder-pool/k8s-clone

# 映射设备
rbd map cinder-pool/k8s-clone --id zhangmingming --keyring /etc/ceph/ceph.client.zhangmingming.keyring

# 创建挂载点并挂载（假设文件系统为 ext4）
mkdir /mnt/k8s-clone
mount /dev/rbd0 /mnt/k8s-clone

rm -rf /mnt/k8s-clone/etc/kubernetes/*

# 卸载并取消映射
umount /mnt/k8s-clone
rbd unmap /dev/rbd0
   
scp /etc/ceph/*  root@osp:/opt/ #将第一套集群的配置上传到osp节点

rbd export  cinder-pool/k8s-clone  k8s-clone.img -c ceph.conf --keyring  ceph.client.admin.keyring #导出成为文件
rm -rf /opt/ceph*
scp /etc/ceph/*  root@osp:/opt/ #将第二套集群的配置上传到osp节点

#容灾站点操作
ceph osd pool create backup-pool #创建备份池
ceph osd pool application enable backup-pool rbd #打标签

#镜像所在节点
rbd import /opt/k8s-clone.img  backup-pool/k8s-image-backup  -c /opt/ceph.conf --keyring /opt/ceph.client.admin.keyring

```
## cinder 对接 ceph
### ceph 节点操作
```shell
# 导出cinder密钥
ceph auth get client.zhangmingming -o /etc/ceph/ceph.client.zhangmingming.keyring
```
### openstack 操作
- 所有节点 (controller && compute1 && compute2)
```shell
# 创建ceph配置文件目录
mkdir /etc/ceph/
# 拷贝密钥和配置文件
scp root@192.168.224.111:/etc/ceph/ceph.client.zhangmingming.keyring /etc/ceph/
scp root@192.168.224.111:/etc/ceph/ceph.conf /etc/ceph/
```
- 计算节点 compute1
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
- 计算节点 compute2
```shell
scp root@192.168.224.111:/etc/ceph/secret.xml /etc/ceph/
cd /etc/ceph

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

# 下面的$(UUID)需要替换
virsh secret-set-value --secret ${UUID} --base64 $(cat ceph.client.zhangmingming.keyring | grep key | awk -F ' ' '{print $3}')
```
- 控制节点 controller
```shell
# 主要作用是OpenStack可调用Ceph资源
yum install -y ceph-common

#配置cinder后端存储
chown cinder.cinder /etc/ceph/ceph.client.zhangmingming.keyring

#修改cinder配置文件
vim /etc/cinder/cinder.conf

# 注意修改rbd_user和rbd_secret_uuid字段
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

# 创建卷测试（可选）
openstack volume create ceph01 --type ceph --size 1
# 查看volumes存储池是否存在卷
rbd ls volumes
```
# openstack 基本步骤（web 界面）
(没有提到但是有，则为默认)
## 身份管理
- 登陆 admin
- 创建项目 EXAM_project
    - 创建项目之后，项目界面点击 EXAM_project 最右边修改配额
        - 计算
            - 实例 10
        - 卷
            - 卷 10（10 个不够，最好多给两个）
        - 网络
            - 浮动 IP 10
            - 安全组 3
- 创建用户 zhangmingming 密码 yutianedu@123
## 网络
### public
- 登陆 admin
- 管理员/网络/网络
    - 创建网络（click）
        - 网络
            - 名称 public
            - 项目 EXAM_project
            - 供应商网络类型 Flat
            - 物理网络 extnet
            - 共享的、外部网络
        - 子网
            - 子网名称 subnet0
            - 网络地址 192.168.224.0/24（宿主机外部网络地址）
            - 网关 IP 192.168.224.8（宿主机外部网络的网关，这里使用的是小米手机热点）
        - 子网详情
            - 分配地址池 192.168.224.80,192.168.224.99（随意）
            - dns 服务器 114.114.114.114
### private
- 登陆用户 zhangmingming
- 项目/网络/网络
    - 创建网络 (click)
        - 网络
            - 名称 private
        - 子网
            - 子网名称 subnet1
            - 网络地址 172.17.10.0/24
            - 网关 IP 172.17.10.254
        - 子网详情
            - 分配地址池 172.17.10.80,172.17.10.99（随意）
### route0
- 登陆用户 zhangmingming
- 项目/网络/路由
    - 新建路由（click）
        - 路由名称 route0
        - 外部网络 public
    - 路由界面点击刚创建的路由名称
        - 接口
            - 添加接口
                - 子网 private

### 安全组
- 登陆用户 zhangmingming
- 项目/网络/安全组
    - 创建三个安全组
- 可以先全部放行 SSH 等配置好之后再关闭

| 名称         | 入口放行                    | 用途     |
| ---------- | ----------------------- | ------ |
| security01 | MYSQL、SSH               | mysql  |
| security02 | HTTP、HTTPS、ALL ICMP、SSH | harbor |
| secutity03 | TCP 8888、SSH            | k8s 业务 |
|            |                         |        |
### 浮动 IP
- 登陆用户 zhangmingming
- 项目/网络/浮动 IP
    - 分配 IP 给项目
        - 分配一些 IP 出来
## 实例类型
- 登陆 admin
- 管理员/计算/实例类型

| 名称                 | VCPU 数量 | 内存   | 根磁盘 |
| ------------------ | ------- | ---- | --- |
| mysql_flavor       | 1       | 2048 | 10  |
| container_flavor01 | 1       | 2048 | 10  |
| container_flavor02 | 2       | 4096 | 20  |
## 镜像
- 登陆 admin
- 管理员/计算/实例类型
    - 创建镜像
        - 镜像名称 centos8_4
        - 文件 centos84.qcow2
        - 架构 x86_64
        - 最小磁盘 10
        - 最低内存 2048
        - 镜像共享公有

## 密钥对
- 可以使用主机 `ssh-keygen` 生成密钥对，在 `/root/.ssh/id_rsa` 和 `/root/.ssh/id_rsa_pub`, 拷贝 pub 公钥内容，私钥可以放在 ansible 主机中方便登陆

- 登陆用户 zhangmingming
- 项目/计算/密钥对
    - 导入公钥
        - 密钥对名称 key01
        - 密钥类型 SSH 密钥
        - 拷贝公钥粘贴

## 实例
### 先创建卷   

- 登陆用户 zhangmingming
- 项目/计算/卷
    - 创建卷

| 卷名称         | 卷来源     | 使用镜像作为源   | 类型   | 大小  |
| ----------- | ------- | --------- | ---- | --- |
| sql01       | 镜像      | centos8_4 | ceph | 10G |
| m01         | 镜像      | centos8_4 | ceph | 10G |
| harbor      | 镜像      | centos8_4 | ceph | 10G |
| discuz      | 镜像      | centos8_4 | ceph | 10G |
| harbor-disk | 没有源，空白卷 | \         | ceph | 10G |
集群先创建一台实例，待共性配置完成后通过镜像复制出其他实例
discuz 用来封装容器镜像
harbor-disk 作为 harbor 数据盘
### 再用卷来创建实例

| 详情：实例名称 | 选择源 volume | 实例类型               | 网络      | 安全组        |
| ------- | ---------- | ------------------ | ------- | ---------- |
| sql01   | sql01      | mysql_flavor01     | private | security01 |
| m01     | m01        | container_flavor01 | private | security03 |
| harbor  | harbor     | container_flavor01 | private | security02 |
| discuz  | discuz     | container_flavor01 | private | security02 |

等到实例创建完成并成功开机后可以将暂时不用的实例挂起
### 为创建的实例分配浮动 IP
# harbor 镜像仓库
## 挂载云硬盘
```shell
mkfs.ext4 /dev/vdb
mkdir -p /data/harbordata/
mount /dev/vdb /data/harbordata/
```
## 创建 harbor 镜像仓库
[harbor安装并配置https_谷歌浏览器 怎么导入harbor证书-CSDN博客](https://blog.csdn.net/networken/article/details/107502461)
[linux - Harbor私有仓库搭建并配置https对接docker与kubernetes - 个人文章 - SegmentFault 思否](https://segmentfault.com/a/1190000043223828)

### 安装 docker
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
### 安装 docker-compose
```shell
wget https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker compose version
```
![[附件/docker-compose-linux-x86_64|docker-compose-linux-x86_64]]
### http 协议搭建
```shell
mkdir -p /data/harbordata/
wget https://github.com/goharbor/harbor/releases/download/v2.11.1/harbor-offline-installer-v2.11.1.tgz
tar -zxvf harbor-offline-installer-v2.11.1.tgz -C /usr/local/
cd /usr/local/harbor
```
#### 修改配置文件
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
修改 daemon. json 文件
```shell
cat >/etc/docker/daemon.json <<EOF
{
    "registry-mirrors": [ "https://e9ede121ca7d4163b95042f86b165fa4.mirror.swr.myhuaweicloud.com" ],
    "insecure-registries": ["http://192.168.224.188","hub.lib0.cn"]
}
EOF
```
重启 docker
```shell
systemctl restart docker
```
安装 harbor
```shell
[root@harbor harbor]# pwd
/usr/local/harbor

./install.sh
```
## 基本使用
- 图形界面创建项目 discuz
- 推送镜像
```shell
# 登陆镜像仓库
docker login http://192.168.224.188
# 提交镜像到镜像仓库
docker images
docker tag nginx 192.168.224.188/discuz/nginx:v1
docker push 192.168.224.188/discuz/nginx:v1
```
- 拉取镜像 (其他主机)

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

# mysql 部署
## 公共步骤 (仅在 sql01 上操作)
### mysql 对接 ceph （上）
```shell
mkdir /etc/ceph
scp root@192.168.224.111:/etc/ceph/ceph.client.zhangmingming.keyring /etc/ceph/
scp root@192.168.224.111:/etc/ceph/ceph.conf /etc/ceph/
# sshpass -p 'redhat' scp root@192.168.224.111:/etc/ceph/ceph.client.admin.keyring /etc/ceph/
yum install ceph ceph-common librados2 librgw-devel librados-devel.x86_64 -y
```
### 安装（上）
```shell
tar -xvf ~/mysql-8.0.41-linux-glibc2.28-x86_64.tar.xz -C /usr/local/
ln -s /usr/local/mysql-8.0.41-linux-glibc2.28-x86_64 /usr/local/mysql
echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile
source /etc/profile
useradd -r -s /sbin/nologin mysql
chown -R mysql:mysql /usr/local/mysql/
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
```
## 以上步骤完成后为 sql01 创建快照，使用快照创建 mysql 集群的其他实例
### 创建快照
- 项目/计算/实例
    - sql01 创建快照
        - 快照名称 sql
### 使用快照创建卷
- 项目/卷/卷
    - 创建卷

| 卷名称   | 卷来源 | 使用快照作为源          | 大小  |
| ----- | --- | ---------------- | --- |
| sql02 | 快照  | snapshot for sql | 10G |
| sql03 | 快照  | snapshot for sql | 10G |

### 使用卷创建实例

| 详情：实例名称 | 选择源 volume | 实例类型         | 网络      | 安全组        |
| ------- | ---------- | ------------ | ------- | ---------- |
| sql02   | sql02      | mysql_flavor | private | security01 |
| sql03   | sql03      | mysql_flavor | private | security01 |
### 为创建的实例分配浮动 IP
## 完成 mysql 安装
### mysql 对接 ceph （下）
#### sql01 对接 ceph
```shell
rbd map mysql-data --pool mysql-pool --id zhangmingming
mkfs.ext4 /dev/rbd0
mkdir -p /data/mysql
mount /dev/rbd0 /data/mysql
```
#### sql02 对接 ceph
```shell
rbd map mysql-data --pool mysql-pool --id zhangmingming
mkfs.ext4 /dev/rbd0
mkdir -p /data/mysql
mount /dev/rbd0 /data/mysql
```
#### sql03 对接 ceph
```shell
rbd map mysql-data --pool mysql-pool --id zhangmingming
mkfs.ext4 /dev/rbd0
mkdir -p /data/mysql
mount /dev/rbd0 /data/mysql
```
### 安装（下）(sql01/sql02/sql03)
```shell
# 对接ceph完成前对/data/mysql/目录的操作是无效的
mkdir -p /data/mysql/{data,log}
chown -R mysql:mysql /data/mysql/

mysqld --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
systemctl enable mysqld
systemctl restart mysqld
systemctl status mysqld

mysqladmin -u root password "yutian"
```
## MGR
(使用的 mysql 版本是 mysql8.0.41，和 5.7 有些不同)
### 配置 hosts 解析
```shell
cat >>/etc/hosts <<EOF
172.17.10.86 sql01
172.17.10.98 sql02
172.17.10.90 sql03
EOF
```
### 修改配置文件
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
```

- sql02
```shell
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
```
- sql03
```shell
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
```
### 重启
```shell
systemctl restart mysqld
mysql -uroot -pyutian
```
### 安装插件
```shell
show plugins; | grep group_replication
install plugin group_replication soname 'group_replication.so'；
```
### 配置账号
```shell
set session sql_log_bin=0;
CREATE USER 'admin'@'172.17.10.%' IDENTIFIED BY 'yutian';
GRANT REPLICATION SLAVE ON *.* TO 'admin'@'172.17.10.%';
flush privileges;
set session sql_log_bin=0;

# 配置MGR服务通道
change master to master_user='admin',master_password='yutian'  for channel 'group_replication_recovery';
# set global group_replication_allow_local_disjoint_gtids_join=ON;（8.0及以后被废弃）
```
### master 节点启动引导，进入 mysql 服务端
```shell
set global group_replication_bootstrap_group=on;
start group_replication;
set global group_replication_bootstrap_group=OFF;
```
### slave 节点进入 mysql 服务端
```shell
start group_replication;
select * from performance_schema.replication_group_members;
```
## 高可用 keepalived+haproxy
https://www.wolai.com/chuangxinyang/wGgUnf6udDBbCqkHTBBvVc
### openstack 操作
```shell
source keystonerc_admin
# 查看网络ID和子网ID并记录
openstack network list
# +--------------------------------------+---------+--------------------------------------+
# | ID                                   | Name    | Subnets                              |
# +--------------------------------------+---------+--------------------------------------+
# | 03fbf7b2-2080-41be-afb6-6f580f1f8b0a | private | 7502364f-9e2f-47f3-b26c-14201e952f3f |
# | 68d064c1-fd0d-47b3-8aa3-5c638727f4da | public  | e7b32612-8d89-42b6-88e4-0e4e48602606 |
# +--------------------------------------+---------+--------------------------------------+
openstack port create --network 03fbf7b2-2080-41be-afb6-6f580f1f8b0a --fixed-ip subnet=7502364f-9e2f-47f3-b26c-14201e952f3f,ip-address=172.17.10.100 viptest
# 查看需要使用vip节点的端口，并记录ID
openstack port list
# sql01 8380bf34-94c0-46bc-8fad-ef59b9268920
# sql02 ae1dd780-0f66-4310-8645-f35c06894e68
# sql03 6fc5982c-d057-4262-b42f-8337d2559db6

# 绑定操作
openstack port set --allowed-address ip-address=172.17.10.100 8380bf34-94c0-46bc-8fad-ef59b9268920
openstack port set --allowed-address ip-address=172.17.10.100 ae1dd780-0f66-4310-8645-f35c06894e68
openstack port set --allowed-address ip-address=172.17.10.100 6fc5982c-d057-4262-b42f-8337d2559db6

# 查看绑定状态
neutron port-show 8380bf34-94c0-46bc-8fad-ef59b9268920
```
### keepalived+haproxy
```shell
yum install -y keepalived haproxy 
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
# sql01配置
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
    interface ens3     # 网卡名
    mcast_src_ip 172.17.10.86   # 本机ip
    virtual_router_id 51
    priority 102
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.86  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.98    # 另外两个节点的ip
      172.17.10.90
    }
    virtual_ipaddress {
        172.17.10.100
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# sql02配置
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
    interface ens3
    mcast_src_ip 172.17.10.98
    virtual_router_id 51
    priority 101
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.98  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.86    # 另外两个节点的ip
      172.17.10.90
    }
    virtual_ipaddress {
        172.17.10.100
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# sql03配置
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
    interface ens3
    mcast_src_ip 172.17.10.90
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.90  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.98    # 另外两个节点的ip
      172.17.10.86
    }
    virtual_ipaddress {
        172.17.10.100
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

frontend sql-master
  bind 0.0.0.0:13306
  bind 127.0.0.1:13306
  mode tcp
  option tcplog
  tcp-request inspect-delay 5s
  default_backend sql-master

backend sql-master
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server sql01  172.17.10.86:3306  check
  server sql02  172.17.10.98:3306  check
  server sql03  172.17.10.90:3306  check
EOF
  
systemctl enable --now haproxy.service

sed -i '/#.*track_script {/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*chk_apiserver/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*}/ s/^#//' /etc/keepalived/keepalived.conf

systemctl restart keepalived
```
## 备份
### 计划任务
```shell
chmod +x /root/mysqldump.sh

crontab -e
0 02 * * 1 /root/mysqldump.sh all 
0 01 * * 1 /root/mysqldump.sh add
```
### 脚本
```shell
#!/bin/bash
#2024年12月17日 15:11:31
#mysql backup
#######################
binlogdir=/data/mysql/data
mysqlbackup=/sql_backup
date1=$(date +%F)
database="ultrax"
backup_log="/sql_backup/backup.log"
#全备
qb(){
  if [ ! -d $mysqlbackup ];then
                mkdir $mysqlbackup
        fi
          if [ ! -d /sqlzip ];then
                mkdir /sqlzip
        fi
  tar -zcf  /sqlzip/mysql_all_$date1.tar $mysqlbackup --remove-files &> /dev/null
  if [ $? -eq 0 ];then
    if [ ! -d $mysqlbackup ];then
                mkdir $mysqlbackup
        fi
    echo -e "\033[40;32m mysql_all_$date1.tar 备份到/opt目录成功\033[0m" &>>$backup_log
  else
    echo -e "\033[40;31m mysql_all_$date1.tar 备份失败，请检查\033[0m" &>>$backup_log
    exit
  fi
  mkdir $mysqlbackup/all

  mysqldump -uroot -p123456 --single-transaction --flush-logs -B ${database} > ${mysqlbackup}/all/${database}_${date1}.sql 
  if [ $? -eq 0 ];then
    echo -e "\033[40;32m全备成功\033[0m" &>>$backup_log
  else
    echo -e "\033[40;32m全备失败\033[0m" &>>$backup_log
    exit
  fi
  num=$[$(cat $binlogdir/binlog.index | wc -l) - 1]
  if [ ! -f $binlogdir/num.txt ];then
    touch $binlogdir/num.txt
  fi
  echo "$num" > $binlogdir/num.txt
}

#增量
zl(){
  if [ ! -d $mysqlbackup/add ];then
    mkdir -p $mysqlbackup/add
  fi
  num=$(cat $binlogdir/num.txt)
  
  mysql -uroot -p123456 -e "flush logs" &> /dev/null
  
  aa=$(cat $binlogdir/binlog.index | wc -l)
  bb=1
  #for i in $(cat $binlogdir/mysql_bin.index)
  #do
  #  binlogname=$(basename $i)
  #done
  
  while [ $bb -lt $aa ]
  do
          if [ $bb -gt  $num ];then
      binlogname=$(sed -n "${bb}p" $binlogdir/binlog.index)
                  cp  /data/mysql/data/$binlogname ${mysqlbackup}/add
      if [ $? -eq 0 ];then
                    echo -e "\033[40;32m${binlogname}增量备份成功\033[0m" &>>$backup_log
            fi
          fi
          bb=$((bb+1))
  done
  num=$[$(cat $binlogdir/binlog.index | wc -l) - 1]
        if [ ! -f $binlogdir/num.txt ];then
                touch $binlogdir/num.txt
        fi
        echo "$num" > $binlogdir/num.txt
}


case "$1" in
  all)
    qb
    ;;
   
  add)
    zl
    ;;
  *)
    echo $"Usage: $0 {all(全备)|add(增量)}"
    ;;
esac
```
# k8s 集群搭建

## 公共步骤（在 m01 上操作）
### 关闭 swap

```shell
sed -ri 's/.*swap.*/#&/g' /etc/fstab
swapoff -a
# 清空iptables规则 
iptables -F
iptables -t nat -F
modprobe -r ip_tables
```
### 系统优化
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
cat /etc/sysctl.d/k8s_better.conf

#开启网桥过滤模块
modprobe br_netfilter
modprobe ip_conntrack
lsmod |grep conntrack
# nf_conntrack          172032  1 nf_nat
# nf_defrag_ipv6         20480  1 nf_conntrack
# nf_defrag_ipv4         16384  1 nf_conntrack
# libcrc32c              16384  4 nf_conntrack,nf_nat,nf_tables,xfs

# sysctl -a | grep net.ipv4.ip_nonlocal_bind
cat >>/etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF
#加载优化
sysctl -p

sysctl -p /etc/sysctl.d/k8s_better.conf

cat /sys/class/dmi/id/product_uuid
# 确保每台服务器的uuid不一致、如果是克隆机器、修改网卡配置文件删除uuid那一行
```
### 安装 IPVS 转发支持
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
cat /etc/sysconfig/modules/ipvs.modules

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
ip_vs_sh               16384  0
ip_vs_wrr              16384  0
ip_vs_rr               16384  0
ip_vs                 172032  6 ip_vs_rr,ip_vs_sh,ip_vs_wrr
nf_conntrack          172032  2 nf_nat,ip_vs
nf_defrag_ipv6         20480  2 nf_conntrack,ip_vs
nf_defrag_ipv4         16384  1 nf_conntrack
libcrc32c              16384  5 nf_conntrack,nf_nat,nf_tables,xfs,ip_vs

```
### 安装 docker (不用 containerd)
```shell
# step 1: 安装必要的一些系统工具
yum install -y yum-utils
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 安装Docker
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```

```shell
#修改cgroup
cat > /etc/docker/daemon.json << EOF

  {
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
    "https://59037eca482c4f14b12dcacc3caffd91.mirror.swr.myhuaweicloud.com",
    "https://docker.1panel.live",
    "https://hub.mirrorify.net",
    "https://docker.m.daocloud.io",
    "https://registry.dockermirror.com",
    "https://docker.aityp.com/",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.icu",
    "https://docker.awsl9527.cn"
  ],
 "insecure-registries": ["hub.lib0.cn"],
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

# Step 4: 开启Docker服务
systemctl enable docker --now
```
### 安装 cri-dockerd
```shell
# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.6/cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.4/cri-dockerd-0.3.4-3.el8.x86_64.rpm
yum -y install cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm

sed -i 's|ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd://|ExecStart=/usr/bin/cri-dockerd --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.9 --container-runtime-endpoint fd://|' /usr/lib/systemd/system/cri-docker.service

systemctl enable cri-docker --now
```
![[附件/cri-dockerd-0.3.6.20231018204925.877dc6a4-0.el8.x86_64.rpm]]
### 安装 k8s 组件
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

# yum clean all
yum makecache
# yum list kubelet --showduplicates | sort -r | grep 1.31
yum install -y kubectl-1.31.7 kubelet-1.31.7 kubeadm-1.31.7

[root@m01 ~]# ls /var/lib/kubelet/
[root@m01 ~]# cat /etc/sysconfig/kubelet 
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"


systemctl enable kubelet --now
# kubeadm config images list --kubernetes-version=v1.31.7

kubeadm config images pull --kubernetes-version=v1.31.7 --image-repository registry.aliyuncs.com/google_containers --cri-socket unix:///run/cri-dockerd.sock

#查看镜像是否拉取成功
docker images
```
以上步骤制作 k8s-img 镜像
### 以上步骤完成后为 m01 创建快照，使用快照创建 k8s 集群的其他实例
#### 创建快照
- 项目/计算/实例
    - m01 创建快照
        - 快照名称 k8s
#### 使用快照创建卷
- 项目/卷/卷
    - 创建卷

| 卷名称 | 卷来源 | 使用快照作为源          | 大小  |
| --- | --- | ---------------- | --- |
| m02 | 快照  | snapshot for k8s | 10G |
| m03 | 快照  | snapshot for k8s | 10G |
| n01 | 快照  | snapshot for k8s | 10G |
| n02 | 快照  | snapshot for k8s | 20G |

#### 使用卷创建实例

| 详情：实例名称 | 选择源 volume | 实例类型               | 网络      | 安全组        |
| ------- | ---------- | ------------------ | ------- | ---------- |
| m02     | m02        | container_flavor01 | private | security03 |
| m03     | m03        | container_flavor01 | private | security03 |
| n01     | n01        | container_flavor01 | private | security03 |
| n02     | n02        | container_flavor02 | private | security03 |
#### 为创建的实例分配浮动 IP
## ip 映射和时间同步
因为前面集群其他实例还没有创建，IP 还未知，所以放到后面进行配置
- 所有节点
```shell
# ip视情况而定，private子网IP
cat >>/etc/hosts <<EOF
172.17.10.87 m01
172.17.10.99 m02
172.17.10.98 m03
172.17.10.93 n01
172.17.10.81 n02
EOF

# 修改
sed -i '/m01/c\172.17.10.87 m01' /etc/hosts
sed -i '/m02/c\172.17.10.99 m01' /etc/hosts
sed -i '/m03/c\172.17.10.98 m01' /etc/hosts
sed -i '/n01/c\172.17.10.93 m01' /etc/hosts
sed -i '/n02/c\172.17.10.81 m01' /etc/hosts

# 互信配置
ssh-keygen -t rsa
for i in m01 m02 m03 n01 n02;do ssh-copy-id -i .ssh/id_rsa.pub $i;done



```
- yum
- m01
```shell
yum -y install chrony
cat >/etc/chrony.conf <<EOF
server ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 172.17.10.0/24
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```
- m02\m03\n01\n02
```shell
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
## master 节点配置高可用
https://www.wolai.com/chuangxinyang/wGgUnf6udDBbCqkHTBBvVc
### openstack 操作
```shell
source keystonerc_admin
# 查看网络ID和子网ID并记录
openstack network list
+--------------------------------------+---------+--------------------------------------+
| ID                                   | Name    | Subnets                              |
+--------------------------------------+---------+--------------------------------------+
| 11fec470-7230-4061-99ab-09774a3216a6 | public  | 3a5563c0-4858-46ec-b457-e1c9671fbd83 |
| 73cbc2f5-6948-4211-b92a-25274ab8ab10 | private | b50213cf-8832-42a4-aa51-be48eddbb334 |
+--------------------------------------+---------+--------------------------------------+
openstack port create --network 73cbc2f5-6948-4211-b92a-25274ab8ab10 --fixed-ip subnet=b50213cf-8832-42a4-aa51-be48eddbb334,ip-address=172.17.10.188 viptest1
# 查看需要使用vip节点的端口，并记录ID
openstack port list
# m01 e2d3061d-7cab-4e4d-a46f-f448168b9077
# m02 5a622ba1-28ae-4be8-81c7-9a4b9411b597
# m03 6bb5c792-41be-4aa8-b5c2-2b93e82169cb

# openstack port set --enable-port-security  e2d3061d-7cab-4e4d-a46f-f448168b9077
# openstack port set --enable-port-security  5a622ba1-28ae-4be8-81c7-9a4b9411b597
# openstack port set --enable-port-security  6bb5c792-41be-4aa8-b5c2-2b93e82169cb

# 绑定操作
openstack port set --allowed-address ip-address=172.17.10.188 e2d3061d-7cab-4e4d-a46f-f448168b9077
openstack port set --allowed-address ip-address=172.17.10.188 5a622ba1-28ae-4be8-81c7-9a4b9411b597
openstack port set --allowed-address ip-address=172.17.10.188 6bb5c792-41be-4aa8-b5c2-2b93e82169cb

# 查看绑定状态
neutron port-show 0e3e8ff2-056d-4f79-8c28-24a4e3b7ca24
neutron port-show f88fe465-9295-45f2-b559-1f1ad241a225
neutron port-show 47a176dd-0959-415c-a13e-2b6d9a8e456a


# unset
# 解除绑定
openstack port unset --allowed-address ip-address=172.17.10.239 2bdf10a9-1939-4da8-b6c0-5c4ac929da46
openstack port unset --allowed-address ip-address=172.17.10.239 76bc6aaa-04d8-402c-9f64-d0ecdf7e3dd4
openstack port unset --allowed-address ip-address=172.17.10.239 baea1a1a-8c27-40af-953e-75673a36f984

# 删除vip
openstack port delete viptest

```

> [!tip] 报错解决
> [root@controller ~(keystone_admin)]# openstack port set --allowed-address ip-address=192.168.224.199 f88fe465-9295-45f2-b559-1f1ad241a225
> ConflictException: 409: Client Error for url: http://192.168.224.100:9696/v2.0/ports/f88fe465-9295-45f2-b559-1f1ad241a225, Port Security must be enabled in order to have allowed address pairs on a port.
> 
### keepalived+haproxy
```shell
yum install -y keepalived haproxy 
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
# m01配置
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
    interface ens3
    mcast_src_ip 172.17.10.87
    virtual_router_id 51
    priority 102
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.87  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.99    # 另外两个节点的ip
      172.17.10.98
    }
    virtual_ipaddress {
        172.17.10.188
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# m02配置
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
    interface ens3
    mcast_src_ip 172.17.10.99
    virtual_router_id 51
    priority 101
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.99  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.87    # 另外两个节点的ip
      172.17.10.98
    }
    virtual_ipaddress {
        172.17.10.188
    }
#    track_script {
#       chk_apiserver
#    }
}
EOF

# m03配置
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
    interface ens3
    mcast_src_ip 172.17.10.98
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 172.17.10.98  # 三个节点此处填本机ip
    unicast_peer {
      172.17.10.99    # 另外两个节点的ip
      172.17.10.87
    }
    virtual_ipaddress {
        172.17.10.188
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
  server master1  172.17.10.87:6443  check
  server master2  172.17.10.99:6443  check
  server master3  172.17.10.98:6443  check
EOF
  
systemctl enable --now haproxy.service
systemctl restart haproxy.service

sed -i '/#.*track_script {/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*chk_apiserver/ s/^#//' /etc/keepalived/keepalived.conf
sed -i '/#.*}/ s/^#//' /etc/keepalived/keepalived.conf

systemctl restart keepalived
```
## 初始化集群

- 关闭 swap
cloud-init 会在创建实例的时候自动开启 swap
```shell
sed -ri 's/.*swap.*/#&/g' /etc/fstab
swapoff -a
cat /etc/fstab
free -m

systemctl restart docker
systemctl status docker
systemctl restart kubelet.service
systemctl status kubelet.service
systemctl restart cri-docker.service
systemctl status cri-docker.service
```
[kubeadm-config说明_kubeadm-config.yaml-CSDN博客](https://blog.csdn.net/wuxingge/article/details/117584071)
```shell
# kubeadm config print init-defaults  > kubeadm-config.yaml
cat >/root/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.224.95  # 本机IP
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: m01
  taints:
  - effect: NoSchedule 
    key: node-role.kubernetes.io/master
  # taints: null
timeouts:
  controlPlaneComponentHealthCheck: 30m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
apiServer:
timeoutForControlPlane: 30m0s
controlPlaneEndpoint: "192.168.224.95:16443"   # 虚拟IP和haproxy端口
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.31.7
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/16
  podNetworkCidr: 10.244.0.0/16
proxy: {}
scheduler: {}
EOF
kubeadm init --config kubeadm-config.yaml


```


```shell
# 在master1节点操作
kubeadm init --control-plane-endpoint=172.17.10.188:16443 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.31.7 --service-cidr=10.96.0.0/16 --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock 
# 初始化失败，删除
kubeadm reset --cri-socket unix:///var/run/cri-dockerd.sock
rm -rf /etc/kubernetes/*
rm -rf ~/.kube/*
rm -rf /var/lib/etcd/*
rm -rf /etc/cni/net.d
iptables -F
iptables -X
ipvsadm --clear

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

scp -r /etc/kubernetes/pki root@m02:/etc/kubernetes/
scp -r /etc/kubernetes/pki root@m03:/etc/kubernetes/
```
### m02\m03 加入集群
```shell
cd /etc/kubernetes/pki/
rm -rf apiserver*
rm -rf etcd/peer.*
rm -rf etcd/server.*
kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
    --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c \
    --control-plane \
    --cri-socket unix:///var/run/cri-dockerd.sock
# 注意上面最后要加一行    
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
### n01\n02 加入集群
```shell
kubeadm join 192.168.224.88:16443 --token smu1nr.m5mp5c7igizdetgl \
    --discovery-token-ca-cert-hash sha256:f416dd60d79ee652b4b6185c77991066ad4178db4f26e08fcdcdc8765a0e5e2c \
    --cri-socket unix:///var/run/cri-dockerd.sock
# 注意上面最后要加一行    
```
## 安装 calico 网络组件
```shell
wget https://docs.tigera.io/archive/v3.25/manifests/calico.yaml

vim calico.yaml
# no effect. This should fall within `--cluster-cidr`.
            - name: CALICO_IPV4POOL_CIDR
              value: "10.244.0.0/16"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens160"

kubectl apply -f calico.yaml
```
![[附件/calico.yaml]]
# discuz 容器镜像制作

[kubernetes-部署LNMP环境运行Discuz - 一颗小豆子 - 博客园](https://www.cnblogs.com/douyi/p/12099701.html)

测试环境:
```shell

git clone https://gitee.com/Discuz/DiscuzX.git
cd /root/DiscuzX/upload
sed -i '1394s/.*/PRIMARY KEY (daytime)/'  install/data/install.sql
sed -i '2691s/.*/  groupid smallint(6) unsigned NOT NULL DEFAULT '0' KEY,/'  install/data/install.sql
sed -i '404s/.*/ PRIMARY KEY (logid)/g' install/data/install.sql
sed -i "s/\$nowdaytime = dgmdate(TIMESTAMP, 'Ymd');/\$nowdaytime = dgmdate(TIMESTAMP, 'YmdHis');/" ./source/class/table/table_common_stat.php

cp -a /root/DiscuzX/upload/* /usr/share/nginx/html/
chmod -R 777 /usr/share/nginx/html/

yum install -y php-mysqli php-xml

```
[Centos8 php7 安装php-json扩展 - 简书](https://www.jianshu.com/p/7d4b42adbe27)
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

推送 harbor
```shell
docker login hub.lib0.cn
# admin redhat
docker tag nginx-discuz:v1 hub.lib0.cn/discuz/nginx-discuz:v1
docker push hub.lib0.cn/discuz/nginx-discuz:v1
```
# k8s 对接 cephfs
pod 使用 ceph 存储
https://www.wolai.com/chuangxinyang/2yQcF1mDBJ3GYMzZrEy58L
## 创建一个子卷组，在 ceph-csi 3.13.0 中要求必须要创建子卷组提供给 pvc 使用 (cs01)
```shell
ceph fs subvolumegroup create k8s_fs k8s-storageclass-volumes
ceph fs subvolumegroup ls k8s_fs
```

## ceph-csi 插件下载
了解 [[ceph-csi]]

[ceph-csi的代码托管地址](https://github.com/ceph/ceph-csi)
[ceph-csi v3.13.0.tar.gz](https://github.com/ceph/ceph-csi/archive/refs/tags/v3.13.0.tar.gz)
![[附件/ceph-csi-3.13.0.zip]]
解压并进入文件夹
```shell
# wget -O ceph-csi-3.13.0.zip https://codeload.github.com/ceph/ceph-csi/zip/refs/tags/v3.13.0
[root@master kubernetes]# pwd
/root/Download/ceph-csi-3.13.0/deploy/rbd/kubernetes
[root@master kubernetes]# ls
csi-config-map.yaml      csi-nodeplugin-rbac.yaml        csi-rbdplugin.yaml   rbd.md
csidriver.yaml           csi-provisioner-rbac.yaml       csi-rbd-sc.yaml
csi-kms-config-map.yaml  csi-rbdplugin-provisioner.yaml  csi-rbd-secret.yaml
```

## ceph-csi 插件安装
### 1 . 生成配置文件 `csi-config-map.yaml`
csi-config-map. yaml 为 ceph-csi 用于连接 ceph monitor 的配置文件
```shell
cat >csi-config-map.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "ceph-csi-config"
data:
  config.json: |-
    [
      {
        "clusterID": "7b7fc60e-fff8-11ef-94d3-000c29c2d345",
        "monitors": [
          "172.16.1.91:6789"
        ],
        "cephFS": {
          "subvolumeGroup": "k8s-storageclass-volumes"
        }
      }
    ]
EOF

```
其中 `clusterID` 和 `monitors` 可以通过命令 `ceph mon dump` 查看，如下：
```shell
[root@ceph1 ~]# ceph mon dump
epoch 1
fsid 7b7fc60e-fff8-11ef-94d3-000c29c2d345
last_changed 2025-03-13T10:48:45.514024+0000
created 2025-03-13T10:48:45.514024+0000
min_mon_release 16 (pacific)
election_strategy: 1
0: [v2:172.16.1.91:3300/0,v1:172.16.1.91:6789/0] mon.ceph1
dumped monmap epoch 1
```

生成后，将新的 ConfigMap 对象存储在 Kubernetes 中：
```shell
kubectl apply -f csi-config-map.yaml
```

### 2 . 为 CSI pod 部署 Ceph 配置的 ConfigMap
除了 csi-config-map. yaml 文件之外，ceph-csi 还需要 ceph. conf 配置文件。
位于 `deploy/ceph-conf.yaml`。
```shell
kubectl create -f ../../ceph-conf.yaml
```

### 3 . 定义 kms 的 configmap
如果没有配置 kms，则创建一个空的 configmap 即可
```shell
cat > csi-kms-config-map.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    {}
metadata:
  name: ceph-csi-encryption-kms-config
EOF
kubectl apply -f csi-kms-config-map.yaml
```
### 4 . 生成 ceph-csi cephx 密钥
将用于认证 ceph 的 keyring 配置为 secret
```shell
cat >csi-cephfs-secret.yaml <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
stringData:
  userID: kubernetes
  userKey: AQDJ4NtnRcjgDxAAGiK1ZsBJJIJbt/ufphubnA==
EOF
```
可在 ceph 集群中查看
```shell
[root@ceph1 ~]# ceph auth ls |grep client
[root@ceph1 ~]# ceph auth get client.kubernetes
[client.kubernetes]
        key = AQDJ4NtnRcjgDxAAGiK1ZsBJJIJbt/ufphubnA==
        caps mgr = "profile rbd pool=kubernetes"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=kubernetes"
exported keyring for client.kubernetes
```

生成后，将新的 Secret 对象存储在 Kubernetes 中：
```shell
kubectl apply -f csi-cephfs-secret.yaml
```

### 5 . 配置 ceph-csi 插件
创建所需的 ServiceAccount 和 RBAC ClusterRole/ClusterRoleBinding Kubernetes 对象。这些对象不一定需要自定义您的 Kubernetes 环境，因此可以从 ceph-csi 部署 YAML 中按原样使用：
```shell
kubectl apply -f csi-provisioner-rbac.yaml 
kubectl apply -f csi-nodeplugin-rbac.yaml
```
最后，创建 ceph-csi 置备程序和节点插件。使用 ceph-csi 容器发行版可能例外，这些对象不会不一定需要针对您的 Kubernetes 环境进行自定义，并且因此，可以从 ceph-csi 部署 YAML 中按原样使用：
```shell
kubectl apply -f csidriver.yaml
kubectl apply -f csi-cephfsplugin-provisioner.yaml
kubectl apply -f csi-cephfsplugin.yaml
```

安装插件用到的镜像列表如下，需要自行下载相关镜像
```shell
docker pull quay.io/cephcsi/cephcsi:v3.13.0
docker pull registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.11.1
docker pull registry.k8s.io/sig-storage/csi-provisioner:v5.0.1
docker pull registry.k8s.io/sig-storage/csi-resizer:v1.11.1
docker pull registry.k8s.io/sig-storage/csi-snapshotter:v8.0.1
```
6. 成功配置后 `kubectl get all` 结果如下:

## 使用 Cephfs设备
### 创建 StorageClass
Kubernetes StorageClass 定义了一类存储。可以创建多个 StorageClass 对象以映射到不同的服务质量级别（即 NVMe 与基于 HDD 的池）和功能。

创建 storageclass 示例如下:
```shell
cat >csi-rbd-sc.yaml <<EOF
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-cephfs-sc
provisioner: cephfs.csi.ceph.com
parameters:
   clusterID: 7b7fc60e-fff8-11ef-94d3-000c29c2d345
   fsName: k8s_fs
   pool: kubernetes-data
   csi.storage.k8s.io/provisioner-secret-name: csi-cephfs-secret
   csi.storage.k8s.io/provisioner-secret-namespace: default
   csi.storage.k8s.io/controller-expand-secret-name: csi-cephfs-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: default
   csi.storage.k8s.io/node-stage-secret-name: csi-cephfs-secret
   csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
EOF

kubectl apply -f csi-rbd-sc.yaml
```
> [! 注意]
> `clusterID`: 7b7fc60e-fff8-11ef-94d3-000c29c2d345
> ` pool`: kubernetes
> 这两个参数需要与 ceph 集群的 ID 和存储池名字对应

### 创建 PersistentVolumeClaim
PersistentVolumeClaim 是用户对抽象存储资源的请求。然后，PersistentVolumeClaim 将关联到 Pod 资源，以配置一个 PersistentVolume，该卷将由 Ceph 块镜像提供支持。可以包含可选的 volumeMode 以在挂载的文件系统之间进行选择 （默认）或基于原始块设备的卷。

以下 YAML 可以是用于向 csi-rbd-sc StorageClass 请求原始块存储：
```shell
cat >ceph-cephfs-pvc.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: discuz
spec:
  storageClassName: csi-cephfs-sc  # StorageClass名称
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF


kubectl apply -f raw-block-pvc.yaml
```
将上述 PersistentVolumeClaim 作为原始块设备绑定到 Pod 资源的演示和示例如下：
```shell
cat > pod.yaml << EOF 
apiVersion: v1
kind: Pod
metadata:
  name: redis
  labels:
    name: redis
spec:
  containers:
  - name: redis
    image: redis:7
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
      - containerPort: 6379
    volumeMounts:
      - name: redis-data
        mountPath: "/data"
  volumes:
    - name: redis-data
      persistentVolumeClaim:
        claimName: test-pvc
EOF
```

# k8s 部署 discuz
https://www.wolai.com/chuangxinyang/wGgUnf6udDBbCqkHTBBvVc
```shell
# 创建命名空间
---
apiVersion: v1
kind: Namespace
metadata:
  name: discuz

# 节点打标签
---
apiVersion: v1
kind: Node
metadata:
  name: n02.novalocal
  labels:
    Discuz-node: "true"

# 使用 deployment 创建资源
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: discuz-deployment
  namespace: discuz
  labels:
    app: discuz
spec:
  replicas: 3
  selector:
    matchLabels:
      app: discuz
  template:
    metadata:
      labels:
        app: discuz
    spec:
      initContainers:
      - name: copy-and-fix-permissions
        image: hub.lab0.cn/discuz/nginx-discuz:v1  # 使用应用镜像
        command: ["sh", "-c", "cp -r /var/www/. /mnt/ && chmod -R 777 /mnt/"]  # 复制后修改权限
        volumeMounts:
        - name: discuz-storage
          mountPath: /mnt  # 临时挂载PVC
      containers:
      - name: discuz
        image: hub.lab0.cn/discuz/nginx-discuz:v1
        resources:
          limits:
            memory: "1Gi"
            cpu: "600m"
          requests:
            memory: "512Mi"
            cpu: "300m"
        volumeMounts:
        - name: discuz-storage
          mountPath: /var/www  # 正式挂载PVC
      volumes:
      - name: discuz-storage
        persistentVolumeClaim:
          claimName: test-pvc
      nodeSelector:
        Discuz-node: "true"

# 定义资源服务暴露方式
---
apiVersion: v1
kind: Service
metadata:
  name: discuz-service
  namespace: discuz
  labels:
    app: discuz
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32222
  selector:
    app: discuz

# 创建 Horizontal Pod Autoscaler (HPA)
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: discuz-hpa
  namespace: discuz
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: discuz-deployment
  minReplicas: 3  # 最小副本数
  maxReplicas: 5  # 最大副本数
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60  # 当 CPU 使用率超过 60% 时扩容
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # 当内存使用率超过 80% 时扩容
```

```shell
# 删除创建的内容
kubectl delete namespace discuz
```

```shell
# harbor仓库要公开，不公开的话需要配置secret
kubectl create secret docker-registry  registrysecret --docker-server=hub.lib0.cn  --docker-username=admin --docker-password=redhat -n aaa
vim /etc/docker/daemon.json
{
  "insecure-registries":["http://192.168.224.51","hub.lib0.cn"]
}
systemctl restart docker

cat >>/etc/hosts <<EOF
192.168.224.51 hub.lib0.cn
EOF

kubectl apply -f aaa.yaml
kubectl -n aaa exec my-app-deployment-6cf8585c47-57np8 -ti -- bash
```

## discuz 用户密码重置
4.3 工程师张三在操作时丢失了 Discuz 平台的管理员用户 admin 的密码，需要将其重置为 yutian@123 。（Discuz 用户存储在 pre_ucenter_members 表中）
  - 解题思路：
      - 查看 pre_ucenter_members 表中张三用户信息
      - 重新创建一个 lisi 用户密码设置为 yutian@123
      - 再此查看 pre_ucenter_members 表信息
      - 复制 lisi 用户 password 字段加密后的密码
      - 使用 update 语句更改 pre_ucenter_members 表中张三用户的 password 字段为 lisi 用户 password 字段一致。
      - 在此尝试张三用户密码是否更改成功
# prometheus 部署
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
安装部署MySQL-Export
```shell
cd /usr/local/src
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.10.0/mysqld_exporter-0.10.0.linux-amd64.tar.gz
tar xf mysqld_exporter-0.10.0.linux-amd64.tar.gz
mv mysqld_exporter-0.10.0.linux-amd64 /usr/local/mysqld_exporter
```
Mysql授权连接
```shell
#要获取监控数据，需要授权程序能够连接到 MySQL。
mysql -uroot -pyutian

GRANT REPLICATION CLIENT, PROCESS ON *.* TO 'exporter'@'localhost' identified by '123456';
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';
flush privileges;
```
启动Mysql-Export服务
```shell
#创建配置信息文件
cat <<EOF>> /usr/local/mysqld_exporter/.my.cnf
[client]
user=exporter
password=123456
EOF

#创建systemd 管理
cat <<EOF>> /usr/lib/systemd/system/mysqld_exporter.service

[Unit]
Description=mysqld_exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/mysqld_exporter/mysqld_exporter --config.my-cnf=/usr/local/mysqld_exporter/.my.cnf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

#设置开机自启动
systemctl daemon-reload
systemctl enable mysqld_exporter --now
systemctl status mysqld_exporter
```
k8s 侧设置
在 Kubernetes 中创建 Service & Endpoints
```shell
cat >mysql-exporter-external.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: mysql-exporter
  namespace: monitoring
  labels:
    app: mysql-exporter
spec:
  ports:
  - name: http-metrics
    port: 9104
    targetPort: 9104
  type: ClusterIP

---
apiVersion: v1
kind: Endpoints
metadata:
  name: mysql-exporter
  namespace: monitoring
subsets:
- addresses:
  - ip: 192.168.224.41  # MySQL 节点 IP
  ports:
  - name: http-metrics
    port: 9104
EOF

#应用Service & Endpoints
kubectl apply -f mysql-exporter-external.yaml
```
创建 ServiceMonitor
```shell
cat >mysql-servicemonitor.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mysql-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: mysql-exporter
  endpoints:
  - port: http-metrics
EOF

#应用ServiceMonitor
kubectl apply -f mysql-servicemonitor.yaml
```
## prometheus 监控 ceph
https://www.wolai.com/chuangxinyang/37Ub1yhJ85vPMZCSwxpBm7
```shell

```
## prometheus 监控 openstack
https://www.wolai.com/chuangxinyang/2yQcF1mDBJ3GYMzZrEy58L
```shell

```


# 收尾（几个小实验）
[[#部署两台单节点 ceph#云硬盘容灾（等到 openstack 创建卷之后针对卷进行备份）(cs01 && cs02)|云硬盘容灾]]
[[#部署两台单节点 ceph#mysql 扩容（放在后面做）|mysql 扩容]]
[[#部署两台单节点 ceph#rbd 卷改造 (放后面做)|rbd 卷改造]]
[[#k8s 部署 discuz#discuz 用户密码重置|discuz 用户密码重置]]
```shell

```

# 问题
- [x] harbor https?
[harbor安装并配置https_谷歌浏览器 怎么导入harbor证书-CSDN博客](https://blog.csdn.net/networken/article/details/107502461)
[linux - Harbor私有仓库搭建并配置https对接docker与kubernetes - 个人文章 - SegmentFault 思否](https://segmentfault.com/a/1190000043223828)
- [x] k8s\mysql 高可用
- [ ] discuz 容器镜像及发布问题
[kubernetes-部署LNMP环境运行Discuz - 一颗小豆子 - 博客园](https://www.cnblogs.com/douyi/p/12099701.html)
- [ ] prometheus 部署
https://www.wolai.com/chuangxinyang/rfURASHc3GpdEY2mvAYzkN
- [x] calico 经常失效问题
- [x] k8s 拉取 http 镜





![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250414235416364.png)
[json_encode()该函数需要 PHP 支持 JSON,确定开启了此项功能 如何解决 - Discuz! X 问题求助 - Powered by Discuz!](https://www.dismall.com/thread-18218-1-1.html)
[Centos8 php7 安装php-json扩展 - 简书](https://www.jianshu.com/p/7d4b42adbe27)


![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250415002256104.png)

[解决连接MySql 8.x 出现 The server requested authentication method unknown to the client-CSDN博客](https://blog.csdn.net/weixin_56260207/article/details/136236700)

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250415003525472.png)
每次报错的位置都不同，怀疑是数据库或 discuz的性能问题
增加 discuz 实例的内存后（原 1C1G 增加至 1C2G）, 初始化成功
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250415010402137.png)
简陋版，笑了。





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





创建实例失败
```shell
# compute1节点的/var/log/nova/nova-compute.log报错：
2025-04-13 20:09:45.840 1518 ERROR nova.compute.manager [req-b3215e1f-5a81-4a85-bfdf-cfc16bf573bf 95ed32b87b764d7985045937334aaa7b 663dd40ff3f24f629afa1d446450ec8b - default default] [instance: ab5be93d-d614-48ca-929f-6745f061e7d5] Failed to build and run instance: libvirt.libvirtError: Secret not found: secret '8f74262d-35b4-45b5-9344-1243357e3a42' does not have a value

# 原因是secret没有value
# 可能是因为cinder对接ceph时忘记执行下面一条命令
[root@compute1 ceph]# virsh secret-set-value --secret 8f74262d-35b4-45b5-9344-1243357e3a42 --base64 $(cat ceph.client.zhangmingming.keyring | grep key | awk -F ' ' '{print $3}')
Secret value set
```



更改实例类型失败
```shell
2025-04-15 20:06:28.006 1531 ERROR oslo_messaging.rpc.server [req-f604e996-1c34-4a9a-9d4c-b172af1678f3 141d99a81511437db36832d997c1610e 1e3d5b0bf3c9496db4074410c1020094 - default default] Exception during message handling: nova.exception.ResizeError: Resize error: not able to execute ssh command: Unexpected error while running command.
Command: ssh -o BatchMode=yes 192.168.224.101 mkdir -p /var/lib/nova/instances/7f6c8587-460c-4c9f-9cdb-1f7ce45775ca
Exit code: 255
Stdout: ''
Stderr: 'Load key "/etc/nova/migration/identity": invalid format\r\nnova_migration@192.168.224.101: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).\r\n'

# ssh密钥连接失败
ssh -i /etc/nova/migration/identity nova_migration@192.168.224.101
Load key "/etc/nova/migration/identity": invalid format
nova_migration@192.168.224.101: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).



[root@controller ~(keystone_admin)]# openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host True
-bash: openstack-config: command not found
[root@controller ~(keystone_admin)]# yum provides "*/openstack-config"
Last metadata expiration check: 0:02:54 ago on Tue 15 Apr 2025 08:28:56 PM CST.
Error: No Matches found
[root@controller ~(keystone_admin)]# yum install -y openstack-utils
Last metadata expiration check: 0:03:16 ago on Tue 15 Apr 2025 08:28:56 PM CST.
No match for argument: openstack-utils
Error: Unable to find a match: openstack-utils

wget https://github.com/redhat-openstack/openstack-utils/archive/refs/tags/2017.1-1.tar.gz
tar -zxvf 2017.1-1.tar.gz
cd openstack-utils-2017.1-1/
cd utils
cp ./* /usr/local/bin/

[root@controller utils(keystone_admin)]# openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host True
/usr/local/bin/openstack-config: line 21: exec: crudini: not found









```

创建实例时不能指定接口
```shell
2025-04-15 23:34:39.145 20758 ERROR nova.compute.manager [req-892208ec-88d8-4aa2-a365-2a85178646c2 95ed32b87b764d7985045937334aaa7b 663dd40ff3f24f629afa1d446450ec8b - default default] Instance failed network setup after 1 attempt(s): nova.exception.PortNotUsable: Port 43c7465e-64fe-4dee-bca5-f6d4e917b93d not usable for instance 4dbb358c-3ee9-47d2-8ae0-27bedf790013.

```


kubeadm 初始化集群超时
```shell
[api-check] Waiting for a healthy API server. This can take up to 4m0s
[api-check] The API server is not healthy after 4m0.495090012s

Unfortunately, an error has occurred:
    context deadline exceeded

This error is likely caused by:
    - The kubelet is not running
    - The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
    - 'systemctl status kubelet'
    - 'journalctl -xeu kubelet'

Additionally, a control plane component may have crashed or exited when started by the container runtime.
To troubleshoot, list all containers using your preferred container runtimes CLI.
Here is one example how you may list all running Kubernetes containers by using crictl:
    - 'crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps -a | grep kube | grep -v pause'
    Once you have found the failing container, you can inspect its logs with:
    - 'crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock logs CONTAINERID'
error execution phase wait-control-plane: could not initialize a Kubernetes cluster
To see the stack trace of this error execute with --v=5 or higher

```

```shell
[root@m01 ~]# kubeadm init --control-plane-endpoint=192.168.224.95:16443 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.31.7 --service-cidr=10.96.0.0/16 --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock
[init] Using Kubernetes version: v1.31.7
[preflight] Running pre-flight checks
    [WARNING FileExisting-tc]: tc not found in system path
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0416 00:54:20.259957    9357 checks.go:846] detected that the sandbox image "registry.aliyuncs.com/google_containers/pause:3.9" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.aliyuncs.com/google_containers/pause:3.10" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local m01.novalocal] and IPs [10.96.0.1 172.17.10.97 192.168.224.95]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost m01.novalocal] and IPs [172.17.10.97 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost m01.novalocal] and IPs [172.17.10.97 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
W0416 00:54:47.376099    9357 endpoint.go:57] [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "admin.conf" kubeconfig file
W0416 00:54:51.877109    9357 endpoint.go:57] [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "super-admin.conf" kubeconfig file
W0416 00:54:57.537428    9357 endpoint.go:57] [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "kubelet.conf" kubeconfig file
W0416 00:55:00.455794    9357 endpoint.go:57] [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
W0416 00:55:02.436721    9357 endpoint.go:57] [endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 11.072497705s
[api-check] Waiting for a healthy API server. This can take up to 4m0s
[api-check] The API server is not healthy after 4m0.495090012s

Unfortunately, an error has occurred:
    context deadline exceeded

This error is likely caused by:
    - The kubelet is not running
    - The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
    - 'systemctl status kubelet'
    - 'journalctl -xeu kubelet'

Additionally, a control plane component may have crashed or exited when started by the container runtime.
To troubleshoot, list all containers using your preferred container runtimes CLI.
Here is one example how you may list all running Kubernetes containers by using crictl:
    - 'crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps -a | grep kube | grep -v pause'
    Once you have found the failing container, you can inspect its logs with:
    - 'crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock logs CONTAINERID'
error execution phase wait-control-plane: could not initialize a Kubernetes cluster
To see the stack trace of this error execute with --v=5 or higher

```