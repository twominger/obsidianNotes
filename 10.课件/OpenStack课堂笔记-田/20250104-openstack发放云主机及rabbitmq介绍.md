检查openstack环境
拍摄快照：建议搭建关机状态下拍快照（秒拍），所有节点都拍，还原快照的时候也是同时还原。

1）控制节点上面会自动多出一块虚拟网卡（虚拟交换机 br-ex），上面跑着controller节点ip地址
2）通过webUI界面进入到openstack控制台，依次点击 管理员-计算-主机聚合，看到所有节点服务已运行
3）通过命令行检查rabbitmq服务 systemctl status rabbitmq-server.service
4）注意：如果ip地址没有获取到或者/etc/hosts 映射文件里面没有映射，都会导致rabbitmq服务启动失败

1.环境搭建（skyline）
纠结：涉及容器技术

搭建skyline之前，首先来简单了解下openstack到底是如何手工搭建的？
1）创建数据库用户密码并授权
2）创建openstack用户授权
3）创建service
4）创建endpoint
5）修改配置文件
6）安装对应的组件软件包
7）启动服务

参考实验手册

2.介绍openstack图形化

项目：project，早期也叫租户 tenant，在开源openstack里面，是一个概念
在云平台上创建很多项目，这些项目（里面的资源）必须得有人管理。

项目和用户之间的关系：
一对一/多

一个项目下，可以有1个或多个用户。

创建用户--分配角色
创建组，把用户加入到组里面，把角色授权给组，简化管理流程。

菜单栏：
项目：只能查看当前用户下的所有资源。
管理员：查看所有项目下所有用户的所有资源。只有具备admin角色的用户才会显示该模块。
身份管理：管理员可以在这里菜单里面创建项目和用户，只有具备admin角色的用户才会显示该模块。

3.使用图形化发放一台云主机

1）创建租户/项目 project：admin
2）创建用户 user：admin
3）创建镜像 image：admin 可以是公共镜像，也可以用普通用户创建，只能否给当前用户使用
4）创建规格 flavor：admin
5）创建私网：普通用户。注意：这里的网络指的是VPC，vpc的私网是自定义的，一定避开openstack集群所使用的ip地址（192.168.44.0/24）。具体创建192.168.66子网
6）创建安全组，设置安全组规则：普通用户
7）创建密钥：普通用户
8）发放云主机：普通用户

cirros镜像官方地址
https://download.cirros-cloud.net/0.6.3/

不同的技术栈，针对同一个名称，含义是不一样的：
instance 实例

数据库：instance 实例 指的是 内存和一系列后台进程
云计算：instance 实例 指的是 ECS 云主机（kvm虚拟机）

云主机发放出来之后，自动分配私网ip地址：192.168.66.198
云主机本质上就是运行在宿主机上的一台kvm虚拟机，这台虚拟机在什么地方呢？
你用kvm命令查看 virsh list 在计算节点上查看即可。

问题：请问当前这个ECS能否ping通外网？
默认无法ping通外网，为什么？
因为目前这个66的网络是在云内部，没有连接到任何的外部网络，所以无法出外网。

9）创建公网：admin，管理员-网络，选择的网段，和集群网段保持一致，192.168.44.网段，网络类型flat，物理网络extnet，网关44.2
10) 创建路由器：普通用户，创建路由器，并选择外部网络（外部网关）
11）创建路由子接口：普通用户，连接私网
截至到目前，ecs云主机可以连接外部网络。

问？在集群侧，ping ECS主机的ip地址能否ping通？不通。
外部到内部连接，必须依赖于EIP弹性公网ip
12）申请EIP（公网ip，浮动ip，EIP都是一个意思）：普通用户，分配浮动IP，关联ECS

现在外部就可以直接通过EIP，连接到ECS内部了。

注意：公有云上，云主机出外网有两种方式（EIP，NAT:EIP）
而在我们实验环境中，云主机出外网使用的路由，有点类似于公有云NAT。
公有云上简单粗暴的方式是直接为ECS绑定EIP，就可以实现自由的流量进出。
实验环境中，不要路由器，只绑定EIP能否出去？是不可以的。因为实验环境的EIP是模拟的网段（实际还是私网ip），所以底层必须依赖路由。

openstack中所有的配置文件都是在/etc/下面：/etc/nova /etc/cinder /etc/glance....
openstack所有的日志文件都是在 /var/log下面：/var/log/nava /var/log/cinder....

云主机到底是怎么调度发放的？
打开nova的debug日志，通过nova-scheduler进行计算调度（综合判定给出权重），所有计算节点中，谁的权重大，就会发放到哪个节点上。
[root@controller nova(keystone_admin)]# pwd
/etc/nova
[root@controller nova(keystone_admin)]# cp nova.conf nova.conf.bak
[root@controller nova(keystone_admin)]# vim nova.conf

691 debug=False
改成 true

重启nova服务，nova服务被集成到了httpd（apache）里面，所以直接重启httpd即可。
systemctl restart httpd
systemctl status httpd

我们来动态观察 nova-scheduler 日志
[root@controller nova(keystone_admin)]# pwd
/var/log/nova

[root@controller nova(keystone_admin)]# tail -f 200 nova-scheduler.log

2025-01-04 11:49:33.232 28021 DEBUG nova.scheduler.filter_scheduler [req-14f0ea0c-1513-43cf-97e3-dd0fabf04a35 f58a3e0691f641fd91bd60d991faa6b1 d5fc6f5212004000a5bf77387d184ae7 - default default] Weighed [WeighedHost [host: (compute2, compute2) ram: 5374MB disk: 58368MB io_ops: 0 instances: 2, weight: 3.0], WeighedHost [host: (compute1, compute1) ram: 5374MB disk: 58368MB io_ops: 0 instances: 2, weight: 3.0]] _get_sorted_hosts /usr/lib/python3.6/site-packages/nova/scheduler/filter_scheduler.py:462

2025-01-04 11:53:42.686 28022 DEBUG nova.scheduler.filter_scheduler [req-7223e653-a8f2-46e2-9e8b-17be96c80790 f58a3e0691f641fd91bd60d991faa6b1 d5fc6f5212004000a5bf77387d184ae7 - default default] Weighed [WeighedHost [host: (compute1, compute1) ram: 5374MB disk: 58368MB io_ops: 0 instances: 2, weight: 3.0], WeighedHost [host: (compute2, compute2) ram: 4350MB disk: 58368MB io_ops: 0 instances: 3, weight: 2.793323889215698]] _get_sorted_hosts /usr/lib/python3.6/site-packages/nova/scheduler/filter_scheduler.py:462

默认谁的权重大，vm就会在哪个节点上创建，如果权重一样，那么会按照先后顺序。

我自己能否手工指定具体发放节点呢？
管理员：创建主机聚合即可

4.命令行
参考在线文档 https://blog.51cto.com/cloudcs/6273775

命令不需要死记硬背，但是你得知道方法，知道如何通过某种途径获取所需要的资源。
开局一条狗，装备全靠打。
开局一条openstack，命令全靠help

图形化界面把之前的资源全部删除干净：
1）清除EIP
2）释放EIP
3）清除路由网关
4）清除路由子接口
5）删除路由器
6）删除ECS
7）普通用户删除私网
8）管理员删除公网

[root@controller ~]# source keystonerc_admin
[root@controller ~(admin)]# openstack user list

1）创建项目 project
[root@controller ~(admin)]# openstack project create project1
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| domain_id   | default                          |
| enabled     | True                             |
| id          | a39bc3a4c1a6435eadd78b6363efd89d |
| is_domain   | False                            |
| name        | project1                         |
| options     | {}                               |
| parent_id   | default                          |
| tags        | []                               |
+-------------+----------------------------------+
[root@controller ~(admin)]# openstack project list
+----------------------------------+----------+
| ID                               | Name     |
+----------------------------------+----------+
| 0b8b2931f10248ffa2307528772e9fd4 | admin    |
| 51c51f035123449e8ba8f82ab5423316 | services |
| a39bc3a4c1a6435eadd78b6363efd89d | project1 |
| d5fc6f5212004000a5bf77387d184ae7 | memeda   |
+----------------------------------+----------+

2) 创建用户 user
[root@controller ~(admin)]# openstack user create --project project1 --password redhat user666
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| default_project_id  | a39bc3a4c1a6435eadd78b6363efd89d |
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 961ca144f9744956a1460a1b66f5b93d |
| name                | user666                          |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
[root@controller ~(admin)]# openstack user list

现在尝试下，该用户能否正常登录
当登录的时候提示 You are not authorized for any projects or domains.
这个提示说明命令行创建的用户，还没有被授权角色。
命令行比图形化麻烦一点，就是需要单独设置角色。

3）设置角色 role
[root@controller ~(admin)]# openstack role add --user user666 --project project1  _member_

4）创建规格 flavor
[root@controller ~(admin)]# openstack flavor create --ram 1024 --disk 1 --vcpus 1 y.666
+----------------------------+--------------------------------------+
| Field                      | Value                                |
+----------------------------+--------------------------------------+
| OS-FLV-DISABLED:disabled   | False                                |
| OS-FLV-EXT-DATA:ephemeral  | 0                                    |
| disk                       | 1                                    |
| id                         | d93a4600-e98a-4986-bac0-37d7bc243e35 |
| name                       | y.666                                |
| os-flavor-access:is_public | True                                 |
| properties                 |                                      |
| ram                        | 1024                                 |
| rxtx_factor                | 1.0                                  |
| swap                       |                                      |
| vcpus                      | 1                                    |
+----------------------------+--------------------------------------+
[root@controller ~(admin)]# openstack flavor list

5）上传镜像 image
[root@controller ~(admin)]# openstack image create --container-format bare --disk-format qcow2 --min-disk 1 --min-ram 1024 --file /share/cirros-0.6.2-x86_64-disk.img --public centos7

6）创建私网 network
如何用命令行切换到普通用户？
[root@controller ~(admin)]# cp keystonerc_admin keystonerc_user
[root@controller ~(admin)]# vim keystonerc_user
[root@controller ~(admin)]# cat keystonerc_user
unset OS_SERVICE_TOKEN
    export OS_USERNAME=user666
    export OS_PASSWORD='redhat'
    export OS_REGION_NAME=RegionOne
    export OS_AUTH_URL=http://192.168.44.100:5000/v3
    export PS1='[\u@\h \W(user)]\$ '

export OS_PROJECT_NAME=project1
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3

创建网络 network
[root@controller ~(user)]# openstack network create vpc666
[root@controller ~(user)]# openstack network list
+--------------------------------------+--------+---------+
| ID                                   | Name   | Subnets |
+--------------------------------------+--------+---------+
| bc462668-8ab1-4bd4-852a-c79aaeec1333 | vpc666 |         |
+--------------------------------------+--------+---------+

为网络创建子网 subnet
[root@controller ~(user)]# openstack subnet create --subnet-range 192.168.88.0/24 --dhcp --gateway 192.168.88.254 --allocation-pool start=192.168.88.100,end=192.168.88.200 --network vpc666 sub-88
[root@controller ~(user)]# openstack network list
+--------------------------------------+--------+--------------------------------------+
| ID                                   | Name   | Subnets                              |
+--------------------------------------+--------+--------------------------------------+
| bc462668-8ab1-4bd4-852a-c79aaeec1333 | vpc666 | 54793fb6-ae4f-45dc-a69a-0dbf70ac7b70 |
+--------------------------------------+--------+--------------------------------------+

[root@controller ~(user)]# openstack subnet list
+--------------------------------------+--------+--------------------------------------+-----------------+
| ID                                   | Name   | Network                              | Subnet          |
+--------------------------------------+--------+--------------------------------------+-----------------+
| 54793fb6-ae4f-45dc-a69a-0dbf70ac7b70 | sub-88 | bc462668-8ab1-4bd4-852a-c79aaeec1333 | 192.168.88.0/24 |
+--------------------------------------+--------+--------------------------------------+-----------------+

7) 创建安全组 sec
[root@controller ~(user)]# openstack security group create sec666
[root@controller ~(user)]# openstack security group list
+--------------------------------------+---------+------------------------+----------------------------------+------+
| ID                                   | Name    | Description            | Project                          | Tags |
+--------------------------------------+---------+------------------------+----------------------------------+------+
| e3b8cc7d-e630-4f33-b57b-609a81bc22c9 | sec666  | sec666                 | a39bc3a4c1a6435eadd78b6363efd89d | []   |
| f4472510-c506-44d5-916c-079f2128c898 | default | Default security group | a39bc3a4c1a6435eadd78b6363efd89d | []   |
+--------------------------------------+---------+------------------------+----------------------------------+------+

添加规则
[root@controller ~(user)]# openstack security group rule create --protocol icmp sec666
[root@controller ~(user)]# openstack security group rule create --protocol tcp --dst-port 22:22 sec666

8）创建密钥对 keypair
[root@controller ~(user)]# openstack keypair create key666 > key666.pem
[root@controller ~(user)]# ls
anaconda-ks.cfg  cloudcs.txt  key666.pem  keystonerc_admin  keystonerc_user
[root@controller ~(user)]# openstack keypair list
+--------+-------------------------------------------------+
| Name   | Fingerprint                                     |
+--------+-------------------------------------------------+
| key666 | 6b:08:d5:b7:47:7d:87:03:74:2b:54:db:11:8b:e5:90 |
+--------+-------------------------------------------------+

9) 发放云主机

[root@controller ~(user)]# openstack server create --image centos7 --flavor y.666 --security-group sec666 --key-name key666 --network vpc666 --min 1 ecs666
+-----------------------------+------------------------------------------------+
| Field                       | Value                                          |
+-----------------------------+------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                         |
| OS-EXT-AZ:availability_zone |                                                |
| OS-EXT-STS:power_state      | NOSTATE                                        |
| OS-EXT-STS:task_state       | scheduling                                     |
| OS-EXT-STS:vm_state         | building                                       |
| OS-SRV-USG:launched_at      | None                                           |
| OS-SRV-USG:terminated_at    | None                                           |
| accessIPv4                  |                                                |
| accessIPv6                  |                                                |
| addresses                   |                                                |
| adminPass                   | Vyw7TmKRPBnB                                   |
| config_drive                |                                                |
| created                     | 2025-01-04T07:08:30Z                           |
| flavor                      | y.666 (d93a4600-e98a-4986-bac0-37d7bc243e35)   |
| hostId                      |                                                |
| id                          | b00f1b69-7168-4b48-bbb5-ece5db248a43           |
| image                       | centos7 (ae80aa67-c5ec-4f2d-bf22-938b35316876) |
| key_name                    | key666                                         |
| name                        | ecs666                                         |
| progress                    | 0                                              |
| project_id                  | a39bc3a4c1a6435eadd78b6363efd89d               |
| properties                  |                                                |
| security_groups             | name='e3b8cc7d-e630-4f33-b57b-609a81bc22c9'    |
| status                      | BUILD                                          |
| updated                     | 2025-01-04T07:08:30Z                           |
| user_id                     | 961ca144f9744956a1460a1b66f5b93d               |
| volumes_attached            |                                                |
+-----------------------------+------------------------------------------------+

[root@controller ~(user)]# openstack server show ecs666
+-----------------------------+----------------------------------------------------------+
| Field                       | Value                                                    |
+-----------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                   |
| OS-EXT-AZ:availability_zone | nova                                                     |
| OS-EXT-STS:power_state      | Running                                                  |
| OS-EXT-STS:task_state       | None                                                     |
| OS-EXT-STS:vm_state         | active                                                   |
| OS-SRV-USG:launched_at      | 2025-01-04T07:08:50.000000                               |
| OS-SRV-USG:terminated_at    | None                                                     |
| accessIPv4                  |                                                          |
| accessIPv6                  |                                                          |
| addresses                   | vpc666=192.168.88.151                                    |
| config_drive                |                                                          |
| created                     | 2025-01-04T07:08:30Z                                     |
| flavor                      | y.666 (d93a4600-e98a-4986-bac0-37d7bc243e35)             |
| hostId                      | 175f3cfe3e481aefc982996e183b6945ecb80e598775904491146812 |
| id                          | b00f1b69-7168-4b48-bbb5-ece5db248a43                     |
| image                       | centos7 (ae80aa67-c5ec-4f2d-bf22-938b35316876)           |
| key_name                    | key666                                                   |
| name                        | ecs666                                                   |
| progress                    | 0                                                        |
| project_id                  | a39bc3a4c1a6435eadd78b6363efd89d                         |
| properties                  |                                                          |
| security_groups             | name='sec666'                                            |
| status                      | ACTIVE                                                   |
| updated                     | 2025-01-04T07:08:51Z                                     |
| user_id                     | 961ca144f9744956a1460a1b66f5b93d                         |
| volumes_attached            |                                                          |
+-----------------------------+----------------------------------------------------------+

10）创建公网（admin）

创建网络
[root@controller ~(admin)]# openstack network create --project project1 --external --share --provider-network-type flat --provider-physical-network extnet public

创建子网
[root@controller ~(admin)]# openstack subnet create --subnet-range 192.168.44.0/24 --dhcp --gateway 192.168.44.2 --allocation-pool start=192.168.44.200,end=192.168.44.230 --network public sub-pub

切换到普通用户
11）创建路由 router

创建路由
[root@controller ~(admin)]# source keystonerc_user
[root@controller ~(user)]# openstack router create r666

分配网关：路由连接公网
[root@controller ~(user)]# openstack router set --external-gateway public r666

分配接口：路由连接私网
[root@controller ~(user)]# openstack router add subnet r666 54793fb6-ae4f-45dc-a69a-0dbf70ac7b70

尝试ECS ping 外网。

12）创建及分配EIP
[root@controller ~(user)]# openstack floating ip create public
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| created_at          | 2025-01-04T07:37:11Z                 |
| description         |                                      |
| dns_domain          | None                                 |
| dns_name            | None                                 |
| fixed_ip_address    | None                                 |
| floating_ip_address | 192.168.44.226                       |
| floating_network_id | c6d77d68-7df4-4c22-91e8-70816f3db000 |
| id                  | 96693d13-68cc-4acd-af5d-1f87eaeb394e |
| name                | 192.168.44.226                       |
| port_details        | None                                 |
| port_id             | None                                 |
| project_id          | a39bc3a4c1a6435eadd78b6363efd89d     |
| qos_policy_id       | None                                 |
| revision_number     | 0                                    |
| router_id           | None                                 |
| status              | DOWN                                 |
| subnet_id           | None                                 |
| tags                | []                                   |
| updated_at          | 2025-01-04T07:37:11Z                 |
+---------------------+--------------------------------------+

[root@controller ~(user)]# openstack server add floating ip ecs666 192.168.44.226

[root@controller ~(user)]# ssh cirros@192.168.44.226
The authenticity of host '192.168.44.226 (192.168.44.226)' can't be established.
ECDSA key fingerprint is SHA256:r7iFZ7FY2zMF7WnhQqE0HmMgAsYvMZvcYAH9fTH3sD8.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.44.226' (ECDSA) to the list of known hosts.
cirros@192.168.44.226's password:
$ sudo -i
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc pfifo_fast qlen 1000
    link/ether fa:16:3e:38:42:97 brd ff:ff:ff:ff:ff:ff
    inet 192.168.88.151/24 brd 192.168.88.255 scope global dynamic noprefixroute eth0
       valid_lft 41408sec preferred_lft 36008sec
    inet6 fe80::f816:3eff:fe38:4297/64 scope link

通过密钥可以访问吗？
注意：命令行生成的密钥，该文件权限有些大，更改权限
[root@controller ~(user)]# ssh -i key666.pem cirros@192.168.44.226
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for 'key666.pem' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "key666.pem": bad permissions
cirros@192.168.44.226's password:

即便有密钥文件，依然提示输入密码
[root@controller ~(user)]# chmod 400 key666.pem
[root@controller ~(user)]# ll
total 68
-rw-------. 1 root root  1068 Sep 21 15:00 anaconda-ks.cfg
-rw-------. 1 root root 51380 Dec 19 21:34 cloudcs.txt
-r--------  1 root root  1676 Jan  4 15:03 key666.pem
-rw-------  1 root root   356 Jan  4 14:17 keystonerc_admin
-rw-------  1 root root   360 Jan  4 14:46 keystonerc_user
[root@controller ~(user)]# ssh -i key666.pem cirros@192.168.44.226
$ sudo -i
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc pfifo_fast qlen 1000
    link/ether fa:16:3e:38:42:97 brd ff:ff:ff:ff:ff:ff
    inet 192.168.88.151/24 brd 192.168.88.255 scope global dynamic noprefixroute eth0
       valid_lft 41238sec preferred_lft 35838sec
    inet6 fe80::f816:3eff:fe38:4297/64 scope link

13）创建及绑定EVS
[root@controller ~(user)]# openstack volume create --size 2 evs01
[root@controller ~(user)]# openstack server add volume ecs666 evs01

[root@controller ~(user)]# ssh -i key666.pem cirros@192.168.44.226
$ sudo -i
# fdisk -l
Disk /dev/vda: 1 GiB, 1073741824 bytes, 2097152 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 83E1BD1F-EF8A-4997-8E0E-65E38FB771F4

Device     Start     End Sectors  Size Type
/dev/vda1  18432 2097118 2078687 1015M Linux filesystem
/dev/vda15  2048   18431   16384    8M EFI System

Partition table entries are not in disk order.


Disk /dev/vdb: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
#

后续操作分区格式化，挂载文件系统等。

有一个小细节：刚才我们手工通过命令行创建出来了一个云硬盘，是可以在图形化界面《卷》里面看到的。
理论上，不管是创建的实例，还是手工单独创建的云硬盘，都可以在 卷 里面看得到。
可是，现在的实际情况是，手工创建的evs可以看到，但是实例自己创建的系统盘evs，在这里看不到。

原因是因为我们在通过命令行启动实例的时候，少带了一个参数 --boot-from-volume

[root@controller ~(user)]# openstack server create --image centos7 --flavor y.666 --security-group sec666 --key-name key666 --network vpc666 --min 1 --boot-from-volume 1 ecs777

如果用命令行在创建云主机的时候，没有带这个参数，那么云主机使用的磁盘空间是当前云主机所在的物理机的磁盘空间；（本地空间）
如果用命令行在创建云主机的时候，带上了--boot-from-volume，云主机使用的磁盘空间是cinder后端对接的存储空间。（云空间）
如果用图形化创建，默认使用的也是cinder后端对接的存储空间。

5.rabbitmq
消息队列中间件有哪些？
RocketMQ
rabbitmq
kafka
....

消息队列主要解决什么问题？
1.解耦应用模块，提升系统的容错性
2.异步消息
3.削峰填谷，抗住并发量

openstack 由众多组件构成一套系统 nova/cinder/glance/neutron/swift.....
openstack 由各个组件构成的
每个组件又是由多个服务构成的。
[root@controller ~(user)]# systemctl list-unit-files |grep cinder
openstack-cinder-api.service                  enabled
openstack-cinder-backup.service               enabled
openstack-cinder-scheduler.service            enabled
openstack-cinder-volume.service               enabled

服务与服务之间是需要通信的，它们是如何实现通信的呢？就是依赖于rabbitmq
rabbitmq 端口有两个
25672：默认rabbitmq消息队列内部组件互通，使用的端口号，不是给客户端使用的。
15672：是rabbitmq给客户端进行访问的端口号，默认没有开启。
[root@controller ~(user)]# netstat -tulnp |grep 567
tcp        0      0 0.0.0.0:25672           0.0.0.0:*               LISTEN      1779/beam.smp
tcp6       0      0 :::5672                 :::*                    LISTEN      1779/beam.smp

因为15672端口需要开启webUI
[root@controller ~(user)]# rabbitmq-plugins list
Listing plugins with pattern ".*" ...
 Configured: E = explicitly enabled; e = implicitly enabled
 | Status: * = running on rabbit@controller
 |/
[  ] rabbitmq_amqp1_0                  3.8.3
[  ] rabbitmq_auth_backend_cache       3.8.3
[  ] rabbitmq_auth_backend_http        3.8.3
[  ] rabbitmq_auth_backend_ldap        3.8.3
[  ] rabbitmq_auth_backend_oauth2      3.8.3
[  ] rabbitmq_auth_mechanism_ssl       3.8.3
[  ] rabbitmq_consistent_hash_exchange 3.8.3
[  ] rabbitmq_event_exchange           3.8.3
[  ] rabbitmq_federation               3.8.3
[  ] rabbitmq_federation_management    3.8.3
[  ] rabbitmq_jms_topic_exchange       3.8.3
[  ] rabbitmq_management               3.8.3
[  ] rabbitmq_management_agent         3.8.3
[  ] rabbitmq_mqtt                     3.8.3
[  ] rabbitmq_peer_discovery_aws       3.8.3
[  ] rabbitmq_peer_discovery_common    3.8.3
[  ] rabbitmq_peer_discovery_consul    3.8.3
[  ] rabbitmq_peer_discovery_etcd      3.8.3
[  ] rabbitmq_peer_discovery_k8s       3.8.3
[  ] rabbitmq_prometheus               3.8.3
[  ] rabbitmq_random_exchange          3.8.3
[  ] rabbitmq_recent_history_exchange  3.8.3
[  ] rabbitmq_sharding                 3.8.3
[  ] rabbitmq_shovel                   3.8.3
[  ] rabbitmq_shovel_management        3.8.3
[  ] rabbitmq_stomp                    3.8.3
[  ] rabbitmq_top                      3.8.3
[  ] rabbitmq_tracing                  3.8.3
[  ] rabbitmq_trust_store              3.8.3
[  ] rabbitmq_web_dispatch             3.8.3
[  ] rabbitmq_web_mqtt                 3.8.3
[  ] rabbitmq_web_mqtt_examples        3.8.3
[  ] rabbitmq_web_stomp                3.8.3
[  ] rabbitmq_web_stomp_examples       3.8.3

启用webui插件
[root@controller ~(user)]# rabbitmq-plugins enable rabbitmq_management
Enabling plugins on node rabbit@controller:
rabbitmq_management
The following plugins have been configured:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
Applying plugin configuration to rabbit@controller...
The following plugins have been enabled:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch

started 3 plugins.

[root@controller ~(user)]# netstat -tulnp |grep 567
tcp        0      0 0.0.0.0:25672           0.0.0.0:*               LISTEN      1779/beam.smp
tcp        0      0 0.0.0.0:15672           0.0.0.0:*               LISTEN      1779/beam.smp
tcp6       0      0 :::5672                 :::*                    LISTEN      1779/beam.smp

这时候直接访问http://192.168.44.100:15672/是访问不到的。为什么？iptables
手工放行
[root@controller ~(user)]# iptables -I INPUT -p tcp --dport 15672 -j ACCEPT

默认的账号和密码 guest/guest

编写两个python文件，让大家看到这个消息队列显示的效果

安装pika库
python3 -m pip install pika -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

编写发送脚本
[root@controller ~(user)]# cat send.py
#!/usr/bin/env python
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='hello')

channel.basic_publish(exchange='', routing_key='hello', body='Hello World!')
print(" [x] Sent 'Hello World!'")
connection.close()

编写接收脚本
[root@controller ~(user)]# cat rev.py
#!/usr/bin/env python
import pika, sys, os

def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
    channel = connection.channel()

    channel.queue_declare(queue='hello')

    def callback(ch, method, properties, body):
        print(f" [x] Received {body}")

    channel.basic_consume(queue='hello', on_message_callback=callback, auto_ack=True)

    print(' [*] Waiting for messages. To exit press CTRL+C')
    channel.start_consuming()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)

运行发送脚本，查看效果
[root@controller ~(user)]# python3 send.py
 [x] Sent 'Hello World!'

在图形化界面里面就可以看到hello消息队列的数量
之后手工运行接收脚本，模拟信息被消费。
[root@controller ~]# python3 rev.py