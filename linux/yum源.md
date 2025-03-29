# 网络源
[阿里巴巴开源镜像站-OPSX镜像站-阿里云开发者社区](https://developer.aliyun.com/mirror/)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319231408983.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319231529168.png)


7.9.2009
```shell
minorver=7.9.2009
sed -e "s|^mirrorlist=|#mirrorlist=|g" \
         -e "s|^#baseurl=http://mirror.centos.org/centos/\$releasever|baseurl=https://mirrors.aliyun.com/centos-vault/$minorver|g" \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo
```

# 本地源

