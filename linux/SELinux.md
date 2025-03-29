# 如何关闭 SELinux
```shell
setenforce 0 
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```
> [! 注意]
> 配置文件关闭 SELinux 之后最好重启一下，避免出现在`permissive` 模式下部署的应用在重启编程`disabled`之后出现异常问题