1.openstack (4-5)
2.docker (1-1.5)
3.k8s (5-6)
4.prometheus (4-5)

年前：计划讲到19号，具体等教务安排。大概讲到k8s。多动手，多整理笔记。
年后：预计2月10开课，具体等教务安排。

周六日两天为什么讲公有云？
1.就业岗位 Linux运维/SER/云原生/云计算运维（拉钩/智联/猎头等要求：公有云）
阿里云/华为云/腾讯云/京东云/火山引擎/青云/天翼云/移动云/九州云....
IaaS 基础设施即服务 ECS/EVS/VPC
PaaS 平台即服务 CCE/RDS
SaaS 软件即服务 云桌面/云客服/云电话/云会议等

2.更好的引出 openstack
Region
AZ
VPC: virtual Private Cloud
对等连接
ECS: Elastic Cloud Service
EVS....


openstack
1.虚拟化技术
1) kvm kernal-based virtual machine 开源免费解决方案
2) VMware(VMware vSphere/VMware workstation/VMware player) 商业版解决方案
3) XEN xen server 开源免费解决方案
云计算厂商底层采用的虚拟化技术方案：kvm

2.引入AWS
2006年推出了一项服务 EC2 Elastic Compute Cloud，把这个东西以服务的形式对外提供。
经历了快20年的云计算技术，到今天为止，也只有唯一一种商业模式：把东西以服务的形式对外售卖。
2010年美国NASA和Rackspace两家公司开源openstack
2008年阿里云 王坚（中国工程院院士），阿里云平台（飞天系统）搭建起来。前后花了10年左右。
其他云计算公司怎么那么快就推出了自家的云平台？
因为国内除了阿里云一家，其他所有云计算公司都是套壳OpenStack

3.了解openstack版本
A-Z 
2017年华为以亚洲第一家白金会员的身份加入openstack社区
华为、阿里
华为、天翼云、移动云等这些云计算公司全部都是依赖于openstack

4.openstack组件
1) nova: 为虚拟机提供计算资源的。华为nova系列，手机里面什么最重要，cpu 最重要，所以nova就是提供计算资源的。
2) glance: 为虚拟机提供镜像资源的，它不存储镜像，专门提供查询、获取服务的。真正的镜像是在对象存储里面保存的。
3) cinder: 为虚拟机提供块存储服务的，提供卷，提供硬盘的。openstack三大存储服务（cinder块存储/swift对象存储/manila文件存储）

You are my Cinderella 灰姑娘，拆分 灰姑娘名字 艾拉 ella，cinder 煤灰、煤渣、炉灰块的意思。
《灰姑娘》2015年迪士尼电影

dirty ella 肮脏的艾拉
cinderella 灰姑娘

4) neutron: 提供网络、子网、端口等服务的。
5) switf: 对象存储，图片、备份、视频、影像、镜像等。百度网盘分布式对象存储。没有修改选项。txt 实则当你双击的时候，直接下载到你本地临时目录里面，当你保存的时候，表面看起来好似直接在线改了，实则重新上传覆盖了。
6) keystone: 提供组件身份认证服务和端点Endpoint列表（url地址），相当于电话簿
7) horizon: 提供dashboard面板服务，提供webUI界面，在界面上操作。
8) heat: 编排服务，通过编辑yaml文件（还没学，暂且理解xml文件），所有资源都定义到该文件中（安全组/实例/规格/镜像等），利用heat组件加载yaml文件，一次性创建所有资源。

openstack只有8个组件吗？不？近40个组件。

5) 搭建openstack

硬盘：100G（精简磁盘，用多少占多少）
因为默认要使用2G充当swift对象存储空间
因为默认要使用20G充当cinder后端对接的lvm空间
因为默认安装的操作系统也要占用空间

内存：8G
建议两台VM：1台controller 2u/4G，1台compute 2u/2G
内存：16G
建议两台VM：1台controller 2u/8G，1台compute 2u4G
内存：32G
建议两台或三台：1台controller 2u8G，1/2台compute 2u4G
内存：64G或大于64G 随便

64G，规划3台，CentOS 8.4（minimal最小化安装，自动分区，不需要手工分区），单张NAT网卡（可上网）
特别注意：听话，所有节点必须手工配置静态IP地址及网关/DNS（为了避免有些同学软硬件兼容性问题）
主机名ip地址配置好
192.168.44.100 controller
192.168.44.101 compute1
192.168.44.102 compute2

搭建openstack方法：
1) 原生手工搭建，一个组件一个组件去安装（没任何技术含量），完全体力活。提前准备好系统。
2) 红帽及开源社区开发的一些工具 packstack/devstack/kolla-ansible等很多工具，提前准备好系统。
3) tripple O (openstack On openstack，先部署一套mini版本openstack，利用其heat编排组件，搭建一套完整的op) ，可以从0到1，完全搭建。BMC 华为私有云部署。

本次我们通过packstack工具进行配置安装。
1.安装centos 8.4
2.制作模板（linux7/8版本完全一致）
https://blog.51cto.com/cloudcs/5258769

关闭DNS和GSS身份认证
修改网卡配置文件
清除machineID
清除密钥文件
关闭虚拟机 init 0

未来需要多少台虚拟机，直接完整克隆即可。

3.配置时钟源
注意：第一段controller，第二段所有compute

4.关闭NetworkManager服务
如果这个服务是在搭建环境之前关闭的，那么一旦重启虚拟机或者关闭再打开虚拟机，是获取不到ip地址的。
如果你想临时关闭虚拟机，那么起来之后默认没有ip地址（NM服务关闭了），这时候想获取ip，很简单
systemctl start NetworkManager
systemctl stop NetworkManager

5.安装packstack工具
注意，仅在controller节点上安装即可。
原理：安装好packstack之后，通过packstack工具生成一个应答文件（默认是一个文本），在这个文本中，记录了安装openstack所需的所有参数。
在这个文件中进行参数配置，完成后，通过packstack工具加载这个应答文件，进行安装。

6.生成并修改应答文件
CONFIG_COMPUTE_HOSTS=192.168.100.128,192.168.100.129
这个参数是指定计算节点ip的，多个节点ip用英文状态的逗号分隔

CONFIG_KEYSTONE_ADMIN_PW=redhat
这个参数是指定未来登录openstack 管理员admin的密码，该密码可以自定义 redhat

CONFIG_PROVISION_DEMO=n
指定是否创建一个demo示例环境，不需要，默认y，改成n

CONFIG_HEAT_INSTALL=y
是否要安装heat编排组件，默认n，改为y

CONFIG_NEUTRON_OVN_BRIDGE_IFACES=br-ex:ens160
最后最为重要：配置网络映射，默认为空，这里的br-ex 是固定的。br-ex 它是控制节点自动创建的一个虚拟交换机（专门通外网的）
也就是说，流量达到了br-ex这个虚拟交换机之后，怎么出去呢？通过物理网卡，物理网卡名字叫什么？ens160，这里一定注意，因为
我们的硬件平台或软件版本不一致，所以你的网卡名称有可能ens33

7.一定记得启用network服务（3个节点全部都要执行）
如果是手工packstack搭建（不是跑脚本），当环境全部搭建完成，记得手工把所有节点的network服务起来。
/usr/lib/systemd/systemd-sysv-install enable network
systemctl start network

如果你把启动network服务这一步忘记了，那么当你关闭重新打开虚拟机的时候，因为获取不到ip地址，所以会导致openstack很多服务无法启动。
比如rabbitmq服务。

今天作业：要求周六前务必把环境准备好。
要么跑脚本搭建openstack
要么手工packstack搭建openstack

