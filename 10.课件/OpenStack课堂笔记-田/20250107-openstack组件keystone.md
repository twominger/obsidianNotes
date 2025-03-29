回顾内容
swift
架构，实验

1.keystone
keystone 身份认证及端点列表Endpoint
首先看一张图

了解keystone涉及到的几个概念：
Region：区域，数据中心
Domain：域，逻辑分区，为了区分不同组织或分公司使用的资源，方便单独核算。在华为云上对应的类似于企业项目，在region下创建多个企业项目来方便单独核算。

keystone对象模型分配关系：范围从大到小
region > Domain > project > group > user 

service：服务
endpoint：端点
token：令牌，是keystone通过Credential产生的一个令牌

类型：默认 fernet，还有UUID/PKI/PKIZ
1.UUID
2.PKI
3.PKIZ
4.Fernet（默认）
前面3种类型，都是需要把token缓存到本地，且持久化到数据库里面的，随着后续环境增加，数据库会越来越大，需要手工定期清理。
第4种，因为是对等验证（通过密钥进行验证），不需要缓存token，也无需持久化到数据库中，轻量级。
UUID和fernet流程表面一样的，但实质不一样
UUID没有加密解密过程，fernet有加密解密过程

keystone开启多域认证登录
1）创建domain
[root@controller ~(admin)]# openstack domain create doabc
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| enabled     | True                             |
| id          | 5975339376ba4db095045683f0cd5710 |
| name        | doabc                            |
| options     | {}                               |
| tags        | []                               |
+-------------+----------------------------------+
[root@controller ~(admin)]# openstack domain list
+----------------------------------+---------+---------+--------------------+
| ID                               | Name    | Enabled | Description        |
+----------------------------------+---------+---------+--------------------+
| 06dbb8a8e15d4d50bd0e4704faa3b181 | heat    | True    |                    |
| 5975339376ba4db095045683f0cd5710 | doabc   | True    |                    |
| default                          | Default | True    | The default domain |
+----------------------------------+---------+---------+--------------------+


2）删除domain
[root@controller ~(admin)]# openstack domain delete doabc
Failed to delete domain with name or ID 'doabc': Cannot delete a domain that is enabled, please disable it first. (HTTP 403) (Request-ID: req-a274409e-411d-48c9-b5b0-cb5ddddb6695)
1 of 1 domains failed to delete.

[root@controller ~(admin)]# openstack domain set --disable doabc
[root@controller ~(admin)]# openstack domain show doabc
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| enabled     | False                            |
| id          | 5975339376ba4db095045683f0cd5710 |
| name        | doabc                            |
| options     | {}                               |
| tags        | []                               |
+-------------+----------------------------------+

[root@controller ~(admin)]# openstack domain delete doabc
[root@controller ~(admin)]#

3）创建domain
[root@controller ~(admin)]# openstack domain create doabc
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| enabled     | True                             |
| id          | fb1c10bd1a0c4c278e6e7509834d4dc8 |
| name        | doabc                            |
| options     | {}                               |
| tags        | []                               |
+-------------+----------------------------------+

一旦创建了多个域，那么在查询的时候，就需要带上对应的domain来查询
[root@controller ~(admin)]# openstack user list --domain doabc
[root@controller ~(admin)]# openstack user list --domain default

4）创建项目
[root@controller ~(admin)]# openstack project create --domain doabc proabc
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description |                                  |
| domain_id   | fb1c10bd1a0c4c278e6e7509834d4dc8 |
| enabled     | True                             |
| id          | c2711cc3b60a4616b0a88245f005c351 |
| is_domain   | False                            |
| name        | proabc                           |
| options     | {}                               |
| parent_id   | fb1c10bd1a0c4c278e6e7509834d4dc8 |
| tags        | []                               |
+-------------+----------------------------------+
[root@controller ~(admin)]# openstack project list --domain doabc
+----------------------------------+--------+
| ID                               | Name   |
+----------------------------------+--------+
| c2711cc3b60a4616b0a88245f005c351 | proabc |
+----------------------------------+--------+

5）创建用户
[root@controller ~(admin)]# openstack user create --domain doabc --project proabc --password redhat douser
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| default_project_id  | c2711cc3b60a4616b0a88245f005c351 |
| domain_id           | fb1c10bd1a0c4c278e6e7509834d4dc8 |
| enabled             | True                             |
| id                  | d11bb6d01b774f3987c06c7e05e60be6 |
| name                | douser                           |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+

6）分配角色
[root@controller ~(admin)]# openstack role add --user douser --project proabc admin
[root@controller ~(admin)]#

7）修改配置文件启用多域登录
[root@controller ~(admin)]# cd /etc/openstack-dashboard/
[root@controller openstack-dashboard(admin)]# pwd
/etc/openstack-dashboard
[root@controller openstack-dashboard(admin)]# ls
cinder_policy.json  glance_policy.json  keystone_policy.json  local_settings  neutron_policy.json  nova_policy.d  nova_policy.json
[root@controller openstack-dashboard(admin)]# vim local_settings

将参数值修改为 True，注意必须是大写的T，严格区分大小写。

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

重启服务：注意提供dashboard服务的组件是horizon，这个服务被集成到httpd
[root@controller ~(admin)]# systemctl restart httpd

测试多域登录。

2.neutron

了解物理网络和虚拟网络
物理网络：指的服务器连接到物理交换机、物理路由器、防火墙等网络设备
虚拟网络：指服务器内部虚拟的交换机、路由器、防火墙。

网卡虚拟化
TAP: 单个虚拟网卡设备，模拟一个二层的网络设备，可以接收和发送二层网包 L2
TUN: tunnel 隧道，模拟一个三层的网络设备，可以接收和发送三层网包 L3
VETH pair: 一对儿虚拟网卡设备，一端进入，一端出去。

交换机虚拟化
LinuxBridge 类型虚拟交换机
OVS OpenVirtualSwitch 类型开放虚拟交换机

如何查询这些虚拟交换机
LinuxBridge类型：brctl show
[root@controller ~(admin)]# brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.02427e894063       no              veth5e4fa25

OVS类型：ovs-vsctl show
[root@controller ~(admin)]# ovs-vsctl show
06769ff7-b429-4b45-8d76-80bbdfe0bc73
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port br-int
            Interface br-int
                type: internal
        Port ovn-ede90b-0
            Interface ovn-ede90b-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.44.101"}
        Port ovn-dce39e-0
            Interface ovn-dce39e-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.44.102"}
    Bridge br-ex
        fail_mode: standalone
        Port br-ex
            Interface br-ex
                type: internal
        Port ens160
            Interface ens160
    ovs_version: "2.13.6"

如果8版本有，直接通过命令安装
yum isntall -y bridge-utils (8.4是在cloud-opensta-victoria这个源里面)

8 stream 没有的话，可以直接在线安装
yum install -y https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/bridge-utils-1.5-9.el7.x86_64.rpm

SDN：software define network 软件定义网络，实现数据的控制面和转发面分离，针对物理网络设备。传统交换机，SDN控制器
SDS：software define storage 软件定义存储


