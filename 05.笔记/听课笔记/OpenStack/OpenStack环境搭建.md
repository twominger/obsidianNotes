
如何检查 OpenStack 是否搭建完成
(1) 控制节点会自动多出一张网卡
(2)


添加 skyline 组件
1) s
2) 
`openstack user list`
`openstack service list`
`openstack endpoint list`

配置文件
`/etc/nova/`
`/etc/cinder/`
. . .

`/root/keystonerc_admin` ：openstack 的环境变量文件，需要 `source` 一下

发放云主机流程
1) 创建租户/项目: admin
2) 创建用户: admin
3) 创建镜像: admin 公共 / 普通用户私有
4) 创建规格: admin
5) 创建私有网络: 普通用户
6) 创建安全组，设置安全组规格: 普通用户
7) 创建密钥: 普通用户
8) 发放云主机



