回顾内容
1.图形化发放ECS
2.命令行发放ECS
3.消息中间件RabbitMQ
1）讲多种中间件的横向对比
2）为什么要用rabbitmq，可以提供哪些功能？作用？

应用解耦：提升整体系统容错性及维护性。
异步提速：消息是异步的，客户端不需要等待所有模块执行成功后再返回消息。客户端--->订单系统--300->财务系统--300->库存系统
削峰填谷：提升系统吞吐量、并发量。流量瞬间暴增（秒杀/新闻热点等）50万请求（生产者）--消息中间件RabbitMQ-->订单系统（消费者，规定最大单秒消费数2000）

1.cinder
提供块存储服务、卷volume服务的。
[root@controller ~(user)]# systemctl list-unit-files |grep cinder
openstack-cinder-api.service                  enabled
openstack-cinder-backup.service               enabled
openstack-cinder-scheduler.service            enabled
openstack-cinder-volume.service               enabled

了解cinder架构
简化：cinder-api --> MQ --> cinder-scheduler --> MQ --> cinder-volume -- 调用对应的驱动创建volume

当前的openstack环境，我们使用的是哪个后端存储呢？
应答文件中
 536 CONFIG_CINDER_BACKEND=lvm
 544 CONFIG_CINDER_VOLUMES_CREATE=y
 547 CONFIG_CINDER_VOLUME_NAME=cinder-volumes
 554 CONFIG_CINDER_VOLUMES_SIZE=20G

[root@controller ~(user)]# vgs
  VG             \#PV \#LV \#SN Attr   VSize   VFree
  cinder-volumes   1   4   0 wz--n- <20.60g 1012.00m

[root@controller ~(user)]# lvs
  LV                                          VG             Attr       LSize   Pool                Origin Data%  Meta%  Move Log Cpy%Sync Convert
  cinder-volumes-pool                         cinder-volumes twi-aotz--  19.57g                            1.11   11.13     

后端使用的lvm目的：为了快速构建一个实验、学习环境。

在cinder配置文件中

436 enabled_backends=lvm

注意：这个名字lvm，你可以自定义，但是自定义的这个名字，一定要和最后配置项名称保持一致。

5257 [lvm]
5258 volume_backend_name=lvm
5259 volume_driver=cinder.volume.drivers.lvm.LVMVolumeDriver
5260 target_ip_address=192.168.44.100
5261 target_helper=lioadm
5262 volume_group=cinder-volumes
5263 volumes_dir=/var/lib/cinder/volumes

生产环境不会拿LVM对接。
课上对接NFS，熟悉流程。
对于cinder如何对接ceph，以及ceph怎么操作，等后续ceph课程。
课外选学（有基础的可以尝试，无基础的缓一缓）
https://blog.51cto.com/cloudcs/6552270
https://blog.51cto.com/cloudcs/6580561
https://blog.51cto.com/cloudcs/6602037
                                          
cinder如何对接NFS
提前准备一台linux NFS服务
1）另外准备一台linux，增加一块50G磁盘空间
2）对50G进行分区格式化操作
3）配置yum源
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

yum clean all
yum repolist all
yum install -y vim net-tools bash-completion nfs-utils

4）NFS服务端是否安装nfs
[root@nfs ~]# rpm -qa |grep nfs
libnfsidmap-2.3.3-41.el8.x86_64
sssd-nfs-idmap-2.4.0-9.el8.x86_64
nfs-utils-2.3.3-41.el8_4.3.x86_64

如果没有
[root@nfs ~]# yum install -y nfs-utils

5）启动nfs服务
[root@nfs ~]# systemctl enable nfs-server.service
[root@nfs ~]# systemctl start nfs-server.service

6）关闭防火墙及SElinux
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

7）编辑映射目录
现在服务端有一个目录 /abc，现在要把这个/abc 50G的目录映射出去，在linux里面，编辑/etc/exports把这个目录映射出去
[root@nfs ~]# vim /etc/exports
[root@nfs ~]# cat /etc/exports
/abc 192.168.44.0/24(rw)

[root@nfs ~]# exportfs -arv
exporting 192.168.44.0/24:/abc

[root@nfs ~]# chmod -R 777 /abc

8）客户端测试
比如找到compute2节点，尝试挂载
[root@compute2 ~]# mount -t nfs 192.168.44.205:/abc /mnt
[root@compute2 ~]# df -Th
Filesystem          Type      Size  Used Avail Use% Mounted on
devtmpfs            devtmpfs  3.9G     0  3.9G   0% /dev
tmpfs               tmpfs     3.9G     0  3.9G   0% /dev/shm
tmpfs               tmpfs     3.9G   18M  3.9G   1% /run
tmpfs               tmpfs     3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/mapper/cl-root xfs        62G  3.4G   58G   6% /
/dev/mapper/cl-home xfs        30G  246M   30G   1% /home
/dev/nvme0n1p1      xfs      1014M  178M  837M  18% /boot
tmpfs               tmpfs     794M     0  794M   0% /run/user/0
192.168.44.205:/abc nfs4       50G  390M   50G   1% /mnt

[root@compute2 ~]# cd /mnt/
[root@compute2 mnt]# touch aaa
[root@compute2 mnt]# ls
aaa
[root@compute2 mnt]# rm -rf aaa
[root@compute2 mnt]# ls

[root@compute2 ~]# umount /mnt


9）修改控制节点cinder配置文件后端定义

436 enabled_backends=lvm,nfs

[nfs] 
nfs_shares_config = /etc/cinder/nfs_sharexxxxxxx--记录的是向哪里访问 NFS服务器
volume_driver = cinder.volume.drivers.nfs.NfsDriver 
volume_backend_name = memeda

[nfs] 
nfs_shares_config = /etc/cinder/abcnfs
volume_driver = cinder.volume.drivers.nfs.NfsDriver 
volume_backend_name = memeda


openstack 里面中我们新增加了一个类型，名字可以自定义abc aaa nfs memeda...
之后，我们需要手工讲自定义的这个memeda 名字和配置文件中volume_backend_name = memeda 进行绑定。

当在界面上选择了类型memeda类型，这时候类型和volume_backend_name进行了绑定，于是就会传送到后端，按照后端定义的驱动及挂载路径进行挂载和创建卷操作。

10）创建挂载文件并修改权限

刚才在配置文件中指定的/etc/cinder/abcnfs 这个文件，目前还不存在，创建并修改权限。
[root@controller cinder(user)]# vim /etc/cinder/abcnfs
[root@controller cinder(user)]# cat /etc/cinder/abcnfs
192.168.44.205:/abc

[root@controller cinder(user)]# chmod 640 abcnfs
[root@controller cinder(user)]# chown root:cinder abcnfs
[root@controller cinder(user)]# ll
total 392
-rw-r-----  1 root   cinder     20 Jan  5 10:51 abcnfs

11）openstack创建卷类型
[root@controller ~(admin)]# cinder type-list
+--------------------------------------+-------------+---------------------+-----------+
| ID                                   | Name        | Description         | Is_Public |
+--------------------------------------+-------------+---------------------+-----------+
| 407ca773-83fd-4519-ab09-5f1561ce6dc7 | iscsi       | -                   | True      |
| 5fd9065d-39a4-4493-997c-edcc816336b8 | __DEFAULT__ | Default Volume Type | False     |
+--------------------------------------+-------------+---------------------+-----------+
[root@controller ~(admin)]# cinder type-create --help
usage: cinder type-create [--description <description>]
                          [--is-public <is-public>]
                          <name>

Creates a volume type.

Positional Arguments:
  <name>                Name of new volume type.

Optional Arguments:
  --description <description>
                        Description of new volume type.
  --is-public <is-public>
                        Make type accessible to the public (default true).
[root@controller ~(admin)]# cinder type-create memedanfs
+--------------------------------------+-----------+-------------+-----------+
| ID                                   | Name      | Description | Is_Public |
+--------------------------------------+-----------+-------------+-----------+
| f003e6cd-3a6f-4a5e-9510-9b2255131315 | memedanfs | -           | True      |
+--------------------------------------+-----------+-------------+-----------+
[root@controller ~(admin)]# cinder type-list
+--------------------------------------+-------------+---------------------+-----------+
| ID                                   | Name        | Description         | Is_Public |
+--------------------------------------+-------------+---------------------+-----------+
| 407ca773-83fd-4519-ab09-5f1561ce6dc7 | iscsi       | -                   | True      |
| 5fd9065d-39a4-4493-997c-edcc816336b8 | __DEFAULT__ | Default Volume Type | False     |
| f003e6cd-3a6f-4a5e-9510-9b2255131315 | memedanfs   | -                   | True      |
+--------------------------------------+-------------+---------------------+-----------+

12）将类型绑定后端配置
[root@controller ~(admin)]# cinder type-key memedanfs set volume_backend_name=memeda

13）重启服务并测试
[root@controller ~(admin)]# systemctl restart openstack-cinder*
在图形化界面测试，选择类型为memedanfs，创建卷
在NFS服务端/abc目录下查看
[root@nfs abc]# ls -lathr
total 0
dr-xr-xr-x. 18 root   root   235 Jan  5 10:23 ..
drwxrwxrwx.  2 root   root    57 Jan  5 10:59 .
-rw-rw-rw-.  1 nobody nobody 10G Jan  5 10:59 volume-5d857243-115c-4f57-a8b5-c8190de2153e

问？openstack中，如何实现，创建一台ECS，让他的系统盘使用NFS空间？
可以将一个镜像创建（封装）成一个卷（这时候会让你选择使用哪个空间），之后通过卷启动ECS。

2.glance
glance主要提供镜像服务：镜像创建、删除、管理维护、检索等。本身不存储镜像。

了解glance架构

glance-api-->V1 Registry V2就合并到了api里面-->查数据库--> 到backend后端定位镜像。

官方图上画的glance对接swift的，glance管理的镜像，都是保存在swift对象存储里面的。但真实情况是这样吗？
MariaDB [(none)]> use glance;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [glance]> show tables;
+----------------------------------+
| Tables_in_glance                 |
+----------------------------------+
| alembic_version                  |
| image_locations                  |
| image_members                    |
| image_properties                 |
| image_tags                       |
| images                           |
| metadef_namespace_resource_types |
| metadef_namespaces               |
| metadef_objects                  |
| metadef_properties               |
| metadef_resource_types           |
| metadef_tags                     |
| migrate_version                  |
| task_info                        |
| tasks                            |
+----------------------------------+
15 rows in set (0.000 sec)

MariaDB [glance]> desc image_locations;
+------------+-------------+------+-----+---------+----------------+
| Field      | Type        | Null | Key | Default | Extra          |
+------------+-------------+------+-----+---------+----------------+
| id         | int(11)     | NO   | PRI | NULL    | auto_increment |
| image_id   | varchar(36) | NO   | MUL | NULL    |                |
| value      | text        | NO   |     | NULL    |                |
| created_at | datetime    | NO   |     | NULL    |                |
| updated_at | datetime    | YES  |     | NULL    |                |
| deleted_at | datetime    | YES  |     | NULL    |                |
| deleted    | tinyint(1)  | NO   | MUL | NULL    |                |
| meta_data  | text        | YES  |     | NULL    |                |
| status     | varchar(30) | NO   |     | active  |                |
+------------+-------------+------+-----+---------+----------------+
9 rows in set (0.001 sec)

MariaDB [glance]> select id,value from image_locations;
+----+--------------------------------------------------------------------+
| id | value                                                              |
+----+--------------------------------------------------------------------+
|  1 | file:///var/lib/glance/images/37458f8d-4164-4823-95ca-7357bf4246a2 |
|  2 | file:///var/lib/glance/images/ae80aa67-c5ec-4f2d-bf22-938b35316876 |
|  3 | file:///var/lib/glance/images/be89c55b-cf62-40a6-89eb-d6a7a0e6e8d4 |
+----+--------------------------------------------------------------------+
3 rows in set (0.000 sec)

[root@controller ~(admin)]# cd /var/lib/glance/images/
[root@controller images(admin)]# pwd
/var/lib/glance/images
[root@controller images(admin)]# ll
total 62784
-rw-r----- 1 glance glance 21430272 Jan  4 10:43 37458f8d-4164-4823-95ca-7357bf4246a2
-rw-r----- 1 glance glance 21430272 Jan  4 14:41 ae80aa67-c5ec-4f2d-bf22-938b35316876
-rw-r----- 1 glance glance 21430272 Jan  4 14:43 be89c55b-cf62-40a6-89eb-d6a7a0e6e8d4

现在glance真实对接的后端存储，是本地文件系统，现在我想对接到swift里面。
swift的空间有2G，这个2G也是模拟出来给我们测试学习使用的。
[root@controller ~(admin)]# df -Th
Filesystem          Type      Size  Used Avail Use% Mounted on
devtmpfs            devtmpfs  3.9G     0  3.9G   0% /dev
tmpfs               tmpfs     3.9G  4.0K  3.9G   1% /dev/shm
tmpfs               tmpfs     3.9G  114M  3.8G   3% /run
tmpfs               tmpfs     3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/mapper/cl-root xfs        62G  7.1G   55G  12% /
/dev/mapper/cl-home xfs        30G  246M   30G   1% /home
/dev/loop0          ext4      1.9G  6.1M  1.7G   1% /srv/node/swiftloopback

现在实现一个功能：当用户上传/注册一个镜像，该镜像不再保存到本地文件系统里面了，而是直接保存到swift对象存储的容器里面。
修改glance配置文件

[root@controller ~(admin)]# vim /etc/glance/glance-api.conf

3057 stores=file,http,swift  glance后端支持的存储类型
3111 default_store=swift 修改默认的存储类型
3982 swift_store_region = RegionOne 修改默认的存储区域 RegionOne
4032 swift_store_endpoint_type = publicURL 使用端点url类型
4090 swift_store_container = glance 容器名前缀，上传镜像，会以glance开头生成一个随机名称
4118 swift_store_large_object_size = 5120 单次最大限制上传文件的大小不能超过5G
4142 swift_store_large_object_chunk_size = 200 大对象按照200M进行切分存储，为了提升性能
4160 swift_store_create_container_on_put = true 容器是否要自动创建
4182 swift_store_multi_tenant = true 是否启用多租户
4230 swift_store_admin_tenants = services swift用户所属的租户/项目
4382 swift_store_auth_version = 2 swift身份认证服务版本，2和3都是使用keystone
4391 swift_store_auth_address = http://192.168.44.100:5000/v3 认证的url地址，地址要在环境变量文件中获取
4399 swift_store_user = swift swift用户名
4408 swift_store_key = 260b5e86407041b5 swfit用户密码，通过应答文件获取 1113 CONFIG_SWIFT_KS_PW=260b5e86407041b5

重启服务并测试
[root@controller ~(admin)]# systemctl restart openstack-glance-api.service

界面上传镜像，现在这个镜像就会保存到swift里面（swift后端对接的是模拟的一个2G空间）
MariaDB [glance]> select id,value from image_locations;
+----+------------------------------------------------------------------------------------------------------------------------------------------------------------+
| id | value                                                                                                                                                      |
+----+------------------------------------------------------------------------------------------------------------------------------------------------------------+
|  1 | file:///var/lib/glance/images/37458f8d-4164-4823-95ca-7357bf4246a2                                                                                         |
|  2 | file:///var/lib/glance/images/ae80aa67-c5ec-4f2d-bf22-938b35316876                                                                                         |
|  3 | file:///var/lib/glance/images/be89c55b-cf62-40a6-89eb-d6a7a0e6e8d4                                                                                         |
|  4 | swift+http://192.168.44.100:8080/v1/AUTH_a39bc3a4c1a6435eadd78b6363efd89d/glance_4c260a9d-365f-4d35-a269-12ae695ea106/4c260a9d-365f-4d35-a269-12ae695ea106 |
+----+------------------------------------------------------------------------------------------------------------------------------------------------------------+
4 rows in set (0.000 sec)

cirros 模拟镜像 20M。自定义镜像如何制作。
自定义镜像有点大，创建一个centos7.8，针对这个系统进行配置，最后将这个kvm虚拟机清除配置、压缩并导出qcow2类型镜像（600M）。
将这个镜像上传openstack平台之后，如果默认使用的后端存储是lvm，有可能报错。
cinder对接NFS，先上传镜像，通过镜像创建卷（类型选择nfs），最后通过卷发放云主机。

1）准备一台linux（图形化）centos 7.6
配置yum源，安装包
[root@yw yum.repos.d]# yum groups install "Virtualization*"
[root@yw yum.repos.d]# yum install -y libguestfs-tools-c.x86_64

2）上传iso镜像，创建kvm虚拟机

[root@yw iso]# qemu-img create -f qcow2 /iso/disk01.qcow2 15g
Formatting '/iso/disk01.qcow2', fmt=qcow2 size=16106127360 encryption=off cluster_size=65536 lazy_refcounts=off 

\#创建 kvm 虚机
virt-install \
--name centos \
--disk path=/iso/disk01.qcow2 \
--vcpus 1 \
--memory 4096 \
--location /iso/CentOS-8.4.2105-x86_64-dvd1. iso \
--network network=default

virt-install \
--name centos \
--disk path=/iso/disk01. qcow2 \
--vcpus 1 \
--memory 2048 \
--location /iso/CentOS-7-x86_64-DVD-2009. iso \
--network network=default

对于linux想说几点
1.生产环境里面的linux，几乎没有图形化。
2.安装linux，系统语言最好English，语言支持包：简体中文
3.最重要：linux主机名，不要大写，不要特殊字符，全部小写（可以带数字），最好保持在8个字符。
错误例子：Abc  abc_abc  abc-abc

centos stream 流版本，先放在开源社区，但有很多bug，反馈，修改，稳定，最后再发布RHEL开源的但不是免费。
后面多关注 Rockylinux/Ubuntu server/openEuler

3）修改kvm虚拟机网卡配置文件
[root@centos ~]# vi /etc/sysconfig/network-scripts/ifcfg-eth0
[root@centos ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE="Ethernet"
BOOTPROTO="dhcp"
NAME="eth0"
DEVICE="eth0"
ONBOOT="yes"

4）配置yum源安装软件包
[root@centos yum.repos.d]# cat abc.repo
[abc]
name = abc
baseurl = https://mirrors.aliyun.com/centos-vault/7.9.2009/os/x86_64/
gpgcheck = 0

yum install -y cloud-utils-growpart cloud-init

5）修改cloud配置文件
目的是为了让云主机可以正确解析到 /etc/resolv.conf 配置文件
[root@centos yum.repos.d]# vim /etc/cloud/cloud.cfg
\#添加内容
 - resolv-conf

6）修改network配置文件
目的是为了让云主机访问元数据的时候避免出错
[root@centos yum.repos.d]# vi /etc/sysconfig/network
[root@centos yum.repos.d]# cat /etc/sysconfig/network
/# Created by anaconda
NOZEROCONF=yes

7）修改grub配置，让ECS日志出现在dashboard

GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"

[root@centos yum.repos.d]# vi /etc/default/grub
[root@centos yum.repos.d]# cat /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet"
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"
GRUB_DISABLE_RECOVERY="true"

[root@centos yum.repos.d]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-1160.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1160.el7.x86_64.img
Found linux image: /boot/vmlinuz-0-rescue-aea8942b17174129abdb2e40b5163d8f
Found initrd image: /boot/initramfs-0-rescue-aea8942b17174129abdb2e40b5163d8f.img
done

最后执行关机
init 0

8）清理kvm虚拟机并生成镜像文件
[root@yw iso]# virsh list --all
 Id    Name                           State
----------------------------------------------------
 -     centos                         shut off

[root@yw iso]# virt-sysprep -d centos
[   0.0] Examining the guest ...
[  37.9] Performing "abrt-data" ...
[  37.9] Performing "backup-files" ...
[  39.6] Performing "bash-history" ...
[  39.6] Performing "blkid-tab" ...
[  39.7] Performing "crash-data" ...
[  39.7] Performing "cron-spool" ...
[  39.7] Performing "dhcp-client-state" ...
[  39.7] Performing "dhcp-server-state" ...
[  39.7] Performing "dovecot-data" ...
[  39.7] Performing "logfiles" ...
[  39.9] Performing "machine-id" ...
[  39.9] Performing "mail-spool" ...
[  39.9] Performing "net-hostname" ...
[  39.9] Performing "net-hwaddr" ...
[  39.9] Performing "pacct-log" ...
[  39.9] Performing "package-manager-cache" ...
[  40.0] Performing "pam-data" ...
[  40.0] Performing "passwd-backups" ...
[  40.0] Performing "puppet-data-log" ...
[  40.0] Performing "rh-subscription-manager" ...
[  40.0] Performing "rhn-systemid" ...
[  40.0] Performing "rpm-db" ...
[  40.0] Performing "samba-db-log" ...
[  40.1] Performing "script" ...
[  40.1] Performing "smolt-uuid" ...
[  40.1] Performing "ssh-hostkeys" ...
[  40.1] Performing "ssh-userdir" ...
[  40.1] Performing "sssd-db-log" ...
[  40.1] Performing "tmp-files" ...
[  40.1] Performing "udev-persistent-net" ...
[  40.1] Performing "utmp" ...
[  40.1] Performing "yum-uuid" ...
[  40.1] Performing "customize" ...
[  40.1] Setting a random seed
[  40.2] Setting the machine ID in /etc/machine-id
[  40.2] Performing "lvm-uuids" ...

virt-sparsify --compress /iso/disk01.qcow2 /iso/centos84.qcow2

[root@yw iso]# virt-sparsify --compress /iso/disk01.qcow2 /iso/centos79.qcow2
[   0.0] Create overlay file in /tmp to protect source disk
[   0.1] Examine source disk
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
[  19.5] Fill free space in /dev/centos/root with zero
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
[  48.0] Clearing Linux swap on /dev/centos/swap
[  50.7] Fill free space in /dev/sda1 with zero
[  54.1] Copy to destination and make sparse
[ 174.3] Sparsify operation completed with no errors.
virt-sparsify: Before deleting the old disk, carefully check that the
target disk boots and works correctly.

之后将镜像注册到openstack平台，通过镜像生成一个volume卷，最后通过卷来创建ECS（提前创建好规格）
对于windows的镜像制作，大家可以参考华为云官方文档
https://support.huaweicloud.com/usermanual-ims/zh-cn_topic_0030713152.html

3.nova
nova提供计算资源的，这个项目是核心中的核心，很多组件都是从nova中分离出去的，比如placement组件（收集各个节点计算资源使用信息）、neutron

nova 架构

nova-api-->nova-scheduler-->nova-compute 负责调用其他资源创建虚拟机--> nova-conductor 写数据库

nova最重要的一点是知道 ECS发放流程
Step1：用户通过Dashboard/CLI 申请创建虚拟机，并以REST API 方式来请求Keystone授权。
Step2：keystone通过用户请求认证信息，并生成auth-token返回给对应的认证请求。
Step3：界面或命令行通过RESTful API向nova-api发送一个boot instance的请求（携带auth-token）。
Step4：nova-api接受请求后向keystone发送认证请求，查看token是否为有效用户和token。
Step5：keystone验证token是否有效，如有效则返回有效的认证和对应的角色（注：有些操作需要有角色权限才能操作）。
Step6：通过认证后nova-api和数据库通讯。
Step7：初始化新建虚拟机的数据库记录。
Step8：nova-api通过rpc.call向nova-scheduler请求是否有创建虚拟机的资源（Host ID）。
Step9：nova-scheduler进程侦听消息队列，获取nova-api的请求。
Step10：nova-scheduler通过查询nova数据库中计算资源的情况，并通过调度算法计算符合虚拟机创建需要的主机。
Step11：对于有符合虚拟机创建的主机，nova-scheduler更新数据库中虚拟机对应的物理主机信息。
Step12：nova-scheduler通过rpc.cast向nova-compute发送对应的创建虚拟机请求的消息。
Step13：nova-compute会从对应的消息队列中获取创建虚拟机请求的消息。
Step14：nova-compute通过rpc.call向nova-conductor请求获取虚拟机消息。
Step15：nova-conductor从消息队队列中拿到nova-compute请求消息。
Step16：nova-conductor根据消息查询虚拟机对应的信息。
Step17：nova-conductor从数据库中获得虚拟机对应信息。
Step18：nova-conductor把虚拟机信息通过消息的方式发送到消息队列中。
Step19：nova-compute从对应的消息队列中获取虚拟机信息消息。
Step20：nova-compute通过keystone的RESTfull API拿到认证的token，并通过HTTP请求glance-api获取创建虚拟机所需要镜像。
Step21：glance-api向keystone认证token是否有效，并返回验证结果。
Step22：token验证通过，nova-compute获得虚拟机镜像信息（URL）。
Step23：nova-compute通过keystone的RESTfull API拿到认证k的token，并通过HTTP请求neutron-server获取创建虚拟机所需要的网络信息。
Step24：neutron-server向keystone认证token是否有效，并返回验证结果。
Step25：token验证通过，nova-compute获得虚拟机网络信息。
Step26：nova-compute通过keystone的RESTfull API拿到认证的token，并通过HTTP请求cinder-api获取创建虚拟机所需要的持久化存储信息。
Step27：cinder-api向keystone认证token是否有效，并返回验证结果。
Step28：token验证通过，nova-compute获得虚拟机持久化存储信息。
Step29：nova-compute根据instance的信息调用配置的虚拟化驱动来创建虚拟机。

4.heat
编排服务，通过编写yaml文件，在yaml文件中定义好资源，heat加载这个yaml文件，就可以一次性将所有资源创建出来。

实例模板
https://blog.51cto.com/cloudcs/6616896
---------------------------------------

heat_template_version: 2018-08-31

description: Simple template to deploy a stack with two virtual machine instances

parameters:
  image_name_1: 
    type: string 
    label: Image ID 
    description: SCOIMAGE Specify an image name for instance1 
    default: 37458f8d-4164-4823-95ca-7357bf4246a2

  public_net:
    type: string
    label: Network ID
    description: SCONETWORK Network to be used for the compute instance
    default: c6d77d68-7df4-4c22-91e8-70816f3db000

resources:
  mykey:
    type: OS::Nova::KeyPair
    properties:
      save_private_key: true
      name: mykey

  web_secgroup:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 22
          port_range_max: 22
        - protocol: icmp

  private_net:
    type: OS::Neutron::Net
    properties: 
      name: private_net

  private_subnet:
    type: OS::Neutron::Subnet
    properties: 
      network_id: { get_resource: private_net }
      cidr: "192.168.55.0/24"
      ip_version: 4
  
  vrouter:
    type: OS::Neutron::Router
    properties: 
      external_gateway_info: 
        network: { get_param: public_net }

  vrouter_interface:
    type: OS::Neutron::RouterInterface
    properties:
      router_id: { get_resource: vrouter }
      subnet_id: { get_resource: private_subnet }

  instance_port:
    type: OS::Neutron::Port
    properties:
      network: { get_resource: private_net }
      security_groups: 
        - default
        - { get_resource: web_secgroup }
      fixed_ips:
        - subnet_id: { get_resource: private_subnet }
  
  floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
      floating_network_id: { get_param: public_net }

  association:
    type: OS::Neutron::FloatingIPAssociation
    properties:
      floatingip_id: { get_resource: floating_ip }
      port_id: { get_resource: instance_port }

  instance1: 
    type: OS::Nova::Server 
    properties:
      image: { get_param: image_name_1 }
      key_name: { get_resource: mykey }
      flavor: y.666
      networks:
      - port : { get_resource : instance_port }

outputs:
  private_key:
    description: Private key
    value: { get_attr: [ mykey, private_key ] }


总结：当你创建ECS报错了，处理流程是什么？
1.查询nova-api日志 /var/log/nova/nova-api（调度阶段报错）
2.查询nova-scheduler日志 /var/log/nova/nova-scheduler
如果调度失败，会看到相关日志
如果调度成功，看不到错误日志
3.查询nova-compute日志，/var/log/nova/nova-compute 到对应计算节点上查询
一般情况下，调用镜像和网络一般不会出问题，往往是在调用cinder的时候很容易出问题。
4.查询cinder日志，cinder-api/cinder-scheduler.....

镜像/规格格式错误，大小错误，都会引起ECS创建失败。
