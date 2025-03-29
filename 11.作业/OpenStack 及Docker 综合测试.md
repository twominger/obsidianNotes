# 1 基础环境搭建
## 1 .1 OpenStack 部署
准备三台虚拟机，均为 2vCPUs | 8GiB 100G 磁盘
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210025850831.png)
分别完成基础配置包括主机名配置，网络配置

| 主机名 | controller     | compute1       | compute2       |
| --- | -------------- | -------------- | -------------- |
| IP  | 192.168.44.100 | 192.168.44.101 | 192.168.44.102 |
在 controller 上运行脚本
[centos8.4_openstack_victoria.sh](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210030858731.sh)
完成 OpenStack 环境部署
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210031007904.png)
## 1 .2 基础配置
创建项目
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210031340661.png)
创建用户
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210031446984.png)
创建镜像
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210031859982.png)
创建规格 (实例类型)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210032103730.png)
创建 vpc
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210032502342.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210032522009.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210032708335.png)
创建安全组
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210033129664.png)
创建密钥对
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210033316387.png)
创建公网
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210034452032.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210034600505.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210034656231.png)

创建路由
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210034948672.png)
# 2 Glance 与 Swift 对接
```shell
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
4408 swift_store_key = 3ba244d59db8414d swfit用户密码，通过应答文件~/cloudcs.txt 获取 1113 行

[root@controller ~(admin)]# systemctl restart openstack-glance-api.service
```
测试上传镜像，自动创建桶并保存镜像
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210052456540.png)
# 3 swift 对接 NFS
## 3 .1 配置 nfs 服务
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210054426542.png)
## 3 .2 对接
创建目录并修改权限
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210055805674.png)
卸载 swift 原来对接的虚拟块设备
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210060219322.png)
挂载 nfs 文件系统
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210060621039.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210060651808.png)
创建 builder, 创建 builder 和 zone 的映射关系
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210061932499.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210062352627.png)
再平衡
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210062455246.png)
测试：
上传镜像
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210063419883.png)
可以看到自动保存在了对象存储中
在 nfs 服务器上可以看到镜像文件
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210063318492.png)
# 4 自定义镜像制作
安装 kvm 虚拟机
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210071700577.png)

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210071745324.png)

修改网络配置文件
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210072543989.png)
配置 yum 源
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210073506231.png)

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210073030578.png)

安装包
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210073636016.png)
修改/etc/cloud/cloud. cfg
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210073856515.png)

编辑 network 文件（/etc/sysconfig/network）
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210074137910.png)

编辑 grub 文件（/etc/default/grub）
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210074425856.png)

重新生成 grub.cfg 文件并关机
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210074545371.png)

清理 kvm 虚拟机并生成镜像文件
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210074755518.png)
这里由于我的根目录空间不足需要重新指定/tmp 目录
```shell
mkdir /iso/tmp
chmod 1777 /data/tmp/

echo 'export TEMP=/iso/tmp' >> /etc/profile
echo 'export TMPDIR=/iso/tmp' >> /etc/profile
source /etc/profile
```
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210085613603.png)

上传镜像
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210090707665.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210090739556.png)
# 5 使用自定义镜像发放 ECS
创建实例类型
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210092332221.png)
创建 ECS 成功
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210093129465.png)
绑定 EIP
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210093320766.png)
测试，ssh 远程连接成功
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250210093555912.png)
# 6 docker 环境部署




