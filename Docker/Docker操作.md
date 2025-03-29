# docker 镜像管理

- docker:docker 安装好之后，提供命令行工具 docker pull/push/run....  
- ctr:docker 安装的时候，containerd 也自动安装了，containerd 本身也有个命令行工具 ctr ，一般是给开发人员底层测试使用的。  
- nerdctl：因为很难用所以 containerd 提供了一个客户端工具，但是这个工具需要你额外去安装 nerdctl,怎么安装这个 [nerdctl](https://github.com/containerd/nerdctl/tree/main)
- crictl: 这个是 k8s 提供的管理镜像的工具。

它们之间命令的区别，参考
[docker-nerdctl-crictl-ctr使用对比](https://blog.csdn.net/u011127242/article/details/132269861)


2024 年 6 月 5 日，受国内上层政策影响，国内网络无法直接拉取 dockerhub 镜像的，加速器也不可以。因为这些镜像都没有经过审查。目前开放原子基金会正在构建这样一套公共镜像仓库，目前测试页面已经下线，正式上线时间请关注官方  
[https://www.openatom.org/](https://www.openatom.org/)

## 镜像从哪里获取 ？
### 1 . docker公开镜像仓库：
- [dockerhub](hub.docker.com)：docker默认镜像仓库，但在国外，需要科学上网
```shell
#docker默认使用dockerhub作为镜像仓库，以下三种方法均可
docker pull docker.io/library/nginx
docker pull docker.io/nginx
docker pull nginx:1.27.4
```
- [daocloud](https://docs.daocloud.io/community/mirror#_3)：DaoCloud 目前收录了 600+ 国外镜像，方便国内用户拉取。只需要在 dockerhub 路径前加上 `m.daocloud.io` 即可。

### 2 . 私人镜像仓库：
完整路径格式  ：registry/namespace/镜像名称[:版本]  
- registry：仓库的地址，公有云厂商域名  
- namespace：华为云（组织 5 个），阿里云（namespace 3个），分类，镜像存放的一个空间。
- 镜像名称：centos/mysql/nginx
- [:版本]：可选，不指定则默认为 `:latest` 

### 3 . 配置加速器:
各个云厂商都会提供一个东西：镜像加速器
[容器镜像服务-控制台](https://console.huaweicloud.com/swr/?agencyId=5bcdbfc6b7824199938e636178e27fb8&region=cn-north-4&locale=zh-cn#/swr/mirror)
目前大型云厂商的加速器，只有华为云的可以使用。
```shell
cat >> /etc/docker/daemon.json <<EOF
{  
"registry-mirrors": [ "https://0aa309b95880f35a0fcfc00928b5d700.mirror.swr.myhuaweicloud.com","https://docker.m.daocloud.io" ]  
}
EOF

systemctl daemon-reload
systemctl restart docker.service
```
> [! 注意]
> 镜像地址每个账号不同，需要到华为云查看。
> 可以同时配置多个加速器地址，地址之间用逗号隔开

## 镜像操作
```shell
docker search mysql # 搜索镜像，默认连接到dockerhub上搜索的，注意网络  
docker pull nginx # 拉取镜像，没有指定镜像的版本tag，默认就是latest  
docker images # 列举当前镜像。  
docker rmi # 删除镜像，注意删除的时候，没有带标签，默认latest  

docker save mysql -o mysql.tar # 保存镜像  
docker load -i mysql.tar # 导入镜像  

docker export -o xxxx.tar container1 # 导出容器文件系统为tar包  
docker import xxxx.tar aaa:v1.0 # 将文件系统包导入，转成镜像，并为这个镜像设置新的tag
```

总结一下docker save和docker export的区别：  
- docker save保存的是镜像（image），docker export保存的是容器（container）；  
- docker load用来载入镜像包，docker import用来载入容器包，但两者都会恢复为镜像；  
- docker load不能对载入的镜像重命名，而docker import可以为镜像指定新名称。

注意：这四个命令 save/load export/import 不可混用。


docker tag 修改镜像名称（registry）和标签的  
[root@docker ~]# docker tag mysql:latest mysql:v8  
[root@docker ~]# docker images  
REPOSITORY TAG IMAGE ID CREATED SIZE  
mysql latest 56a8c14e1404 2 months ago 603MB  
mysql v8 56a8c14e1404 2 months ago 603MB

这里需要注意：如果imageID一样，是不能够批量删除的，只能单个手工删除。  
[root@docker ~]# docker rmi $(docker images -qa)  
Error response from daemon: conflict: unable to delete 56a8c14e1404 (must be forced) - image is referenced in multiple repositories  
Error response from daemon: conflict: unable to delete 56a8c14e1404 (must be forced) - image is referenced in multiple repositories  
Error response from daemon: conflict: unable to delete 56a8c14e1404 (must be forced) - image is referenced in multiple repositories  
Error response from daemon: conflict: unable to delete 56a8c14e1404 (must be forced) - image is referenced in multiple repositories

批量删除镜像  
docker rmi $(docker images -qa)

镜像推送  
三步走：第一步和第二步可以互换顺序  
1.docker login  
2.docker tag  
3.docker push

解决什么问题的？  
你有一个镜像，是自定义的，或者用很顺手，或是你们公司的业务镜像。你当然可以直接通过save把他导出来，但你导出来是离线的tar包。不好共享。  
如果这时候你有一个公开的镜像仓库地址，直接把地址给他，它就可以直接pull了。

你提供的这个地址，是如何生成的？  
借助公有云厂商的容器镜像服务了。  
因为这个容器镜像服务是我自己的，我个人的，所以上传推送镜像就必须是我本人。公有云厂商如何确定你就是账户本人呢？通过docker login登录

```shell
[root@docker docker]# docker login --username=aliyun0025329374 crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
[root@docker docker]# docker tag nginx:latest crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx:v1
[root@docker docker]# docker images
REPOSITORY                                                                   TAG       IMAGE ID       CREATED       SIZE
nginx                                                                        latest    53a18edff809   5 weeks ago   192MB
crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx   v1        53a18edff809   5 weeks ago   192MB
[root@docker docker]# docker push crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx:v1
The push refers to repository [crpi-on4n8clbhol74dg8.cn-hangzhou.personal.cr.aliyuncs.com/superming/nginx]
03d9365bc5dc: Pushed 
d26dc06ef910: Pushed 
aa82c57cd9fe: Pushed 
d98dcc720ae0: Pushed 
ad2f08e39a9d: Pushed 
135f786ad046: Pushed 
1287fbecdfcc: Pushed 
v1: digest: sha256:c9f91949187fa1c2b4615b88d3acf7902c7e2d4a2557f33ca0cf90164269a7ae size: 1778
```

# docker 容器管理

创建容器的前提：必须得有镜像

查看正在运行的容器  
```shell
docker ps
```

查看所有容器（运行的，非运行的，全部）  
```shell
docker ps -a
```

```shell
[root@docker ~]# docker run centos  
[root@docker ~]# docker ps -a  
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES  
1ce84e0c03e0 centos "/bin/bash" 55 seconds ago Exited (0) 54 seconds ago upbeat_spence
```


```shell
docker history RIPOSITORY:TAG   # 查看镜像的封装分层信息
```
创建了一个容器，但这个容器状态不正常，退出状态。  
容器是专门跑应用服务的，一旦应用服务停止/退出，那么容器就会退出。  
容器里面运行什么任务/服务，是由镜像来决定的。

终端和/bin/bash的关系

/bin/bash bash shell，是命令行的解释器，shell解释用户输入的命令，请问用户在哪里输入命令？在终端（显示器，显示区域，给用户提供输入区域）。  
启动一个/bin/bash 进程，对应的就会启动一个终端，给用户提供输入的地方。

手工为其添加一个伪终端  
docker run -t centos

添加了一个伪终端后，发现虽然可以进入容器，但是执行命令的时候没反应。那是因为没有设置命令行交互，所以为其添加交互。

docker run -t -i centos  
docker run -ti centos

这时候可以进入容器了，也可以执行对应的命令行交互了，但是发现执行exit退出容器的时候，容器直接关闭掉了。为什么？  
因为centos默认运行的是/bin/bash，当创建容器自动进入到容器里面的时候，当前会话其实用的就是默认CMD指定的/bin/bash，执行exit，就相当于结束了默认运行的进程服务，因此进程服务一旦终止，容器就会退出。








