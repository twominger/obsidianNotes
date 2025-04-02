- 下载yum源增加rpm包工具
```shell
yum install createrepo -y
```
- 下载rpm包到指定目录下 如：
```shell
yum install nginx --downloadonly --downloaddir=/centos8/zmm/Packages/
```
- 每加入一个rpm包就要更新一下
```shell
createrepo --update /centos8/zmm/
```


```shell

```