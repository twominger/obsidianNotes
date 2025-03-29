内容回顾
1.docker和k8s商业战争
2.docker架构（客户端/服务端daemon/Registry）
3.docker 镜像管理[镜像 REPOSITORY 构成]
1）云厂商域名地址 swr...huaweicloud....north4...  ....aliyun.com.....  默认为docker.io
2）云厂商提供的ns/组织/仓库，逻辑空间
3) 镜像名称:tag 如果没有带最后的tag标签，默认用 latest
docker pull nginx --> docker pull docker.io/library/nginx:latest

4.docker 容器管理

--------------
1.容器管理
1.1 理解容器原理
docker ps
docker ps -a
docker run
docker create

容器专门为应用而生的。应用如果运行，容器运行，应用结束，容器退出。
应用可以看作是一个正在运行的任务。

- 如何给容器下达任务，让他运行？

任务分为两种：长期任务（守护进程 mysqld/nginx/循环任务等）/短期任务（执行某个命令/单次脚本等）

容器是要依赖于镜像，如果在启动容器的时候，没有手工指定任务，那么容器默认会运行 构建镜像的时候默认指定的任务。
镜像里面默认指定运行的是什么呢？
可以通过docker history centos:latest 查看镜像默认要运行什么东西？这个运行的任务是由哪个参数指定的呢？CMD
后续 FROM/LABEL/MAINTAINER/RUN/ADD/COPY/WORKDIR/CMD/ENTRYPOINT....
docker run centos

- 容器是怎么知道任务结束了呢？
容器的生命周期是由主进程来决定，容器通常会将一个程序或者任务（默认镜像CMD指定的）作为主进程启动（PID=1）.
当容器的这个主进程结束掉（PID=1结束），容器就会任务任务退出，容器退出。

[root@docker ~]# docker run -tid centos

这时候你说我要进入容器，怎么进入？
两种方式:
1.attach 它是以附加的方式，使用容器默认的PID=1的这个父进程/bin/bash，所以当执行exit退出的时候，相当于把PID=1父进程给结束，所以容器退出。
2.exec  exec -ti xxx /bin/bash  通过exec又为容器分配了一个/bin/bash进程，并且分配了伪终端-t来劫持/承载这个进程，通过观察，当前容器系统里面的进程状态如下
[root@docker ~]# docker exec -ti 8 /bin/bash
[root@8078994df8d1 /]# ps -ef
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 01:48 pts/0    00:00:00 /bin/bash
root          15       0  0 01:50 pts/1    00:00:00 /bin/bash
root          28      15  0 01:50 pts/1    00:00:00 ps -ef

当exec进入容器，执行exit的时候，实则退出的是PID=15的进程，而不是PID=1的进程，也正是因为这个原因，所以执行exit退出之后，容器依然运行。
注意：attach这个附加命令，只能用于 /bin/bash 或 /bin/sh ，像centos/alpine/ubuntu/busybox....


容器在运行的时候，能手工指定任务吗？能
[root@docker ~]# docker run -tid centos sleep 3600
599a0f0b6775500fcad9a56ebd1639fc77404485bfa94e97361bfa94127e5a9a
[root@docker ~]#
[root@docker ~]#
[root@docker ~]# docker exec -ti 5 /bin/bash
[root@599a0f0b6775 /]# ps -ef
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 02:03 pts/0    00:00:00 /usr/bin/coreutils --coreutils-prog-shebang=sleep /usr/bin/sleep 3600
root           7       0  0 02:03 pts/1    00:00:00 /bin/bash
root          20       7  0 02:03 pts/1    00:00:00 ps -ef

通过这个例子，看到，默认镜像里面CMD指定的任务，是可以被随时覆盖的。

- 如果一个容器里面运行了多个任务，结束其中一个任务，容器会结束吗？

前提：一个容器不会让他运行多个任务，容器本身就是为应用而生，用nginx就由nginx，用mysql就有mysql

vim run.sh

systemctl start mysqld
systemctl start httpd
nginx -g "daemon off;" 前端进程

docker run -tid centos run.sh

1) 如果手工mysqld服务关闭，不会
2）手工mysqld和httpd都关闭，不会
3）如果手工直接关闭或者结束 nginx，会退出


1.2 容器命令操作
docker run -t -i -d centos

指定容器名称
docker run -tid --name os1 centos

指定容器中的主机名
docker run -tid --name os2 -h os2 centos

指定容器当退出的时候自动重启
docker run -tid --name os6 --restart always centos

用完即止
docker run -ti --name os1 -h os1 --rm centos
当执行exit退出的时候，会自动把临时容器remove掉。

创建mysql
-e 是为容器指定环境变量的
docker run -tid --name db -h db -e MYSQL_ROOT_PASSWORD=redhat mysql

查询日志及详细信息
docker logs db
docker inspect db |grep -i ipaddr
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.2",
                    "IPAddress": "172.17.0.2",

[root@docker ~]# mysql -uroot -predhat -h 172.17.0.2
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 9.1.0 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.003 sec)

MySQL [(none)]>

需求：想让外部的三方工具访问mysql容器
docker run -tid --name db -h db -e MYSQL_ROOT_PASSWORD=redhat -p 33306:3306 mysql
之后，通过工具输入宿主机ip，端口为 33306 ，即可连接mysql容器

创建一个nginx
docker run -tid --name web -h web nginx

需求：让nginx作为web服务端，对外提供访问
需要通过 -p 参数进行端口映射

docker run -tid --name web -h web -p 5500:80 nginx

这样，通过输入宿主机ip:5500就可以访问到nginx web服务。

在宿主机和容器之间进行文件拷贝
docker cp index.html web:/usr/share/nginx/html/
docker cp web:/usr/share/nginx/html/index.html .

容器命令总结：
docker ps
docker ps -a
docker run（-t -i -d -p -e -h --name --restart --rm[和-d --restart 冲突]）
docker rm
docker rm -f
docker attach
docker exec -ti 推荐大家使用,后续学习k8s  kubectl exec -ti 
docker history 查看镜像的分层信息
docker rm -f $(docker ps -qa) 批量删除容器
docker logs
docker inspect
docker cp
docker commit 将容器提交/生成为一个镜像 docker commit os1 centos:666
docker stop/start/restart 停止/启动/重启
docker -h

小练习：通过容器快速部署一个博客 wordpress
docker run -tid --name db -h db -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_DATABASE=wordpress mysql
docker run -tid --name web -h web -e WORDPRESS_DB_HOST=172.17.0.2 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=redhat -e WORDPRESS_DB_NAME=wordpress -p 5000:80 wordpress

思维方式：容器的ip地址不是固定的，所以生产中不会直接让外部流量访问容器。服务service---端点endpoint

2.网络管理
2.1 容器互联Link
docker run -tid --name db -h db -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_DATABASE=wordpress mysql
docker run -tid --name web -h web --link db:aliasdb -e WORDPRESS_DB_HOST=aliasdb -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=redhat -e WORDPRESS_DB_NAME=wordpress -p 5000:80 wordpress

为db使用link创建一个别名，之后参数 WORDPRESS_DB_HOST=aliasdb 不再指定固定ip地址，而是使用别名。

[root@docker ~]# docker inspect db |grep -i ipaddr
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.2",
                    "IPAddress": "172.17.0.2",
[root@docker ~]# docker inspect web |grep -i ipaddr
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.3",
                    "IPAddress": "172.17.0.3",

[root@docker ~]# docker stop db
db
[root@docker ~]# docker run -tid --name os1 -h os1 centos
b5999bee7657d925043fd163687d4d4e95a7ee9def0fe0bf18159d65fc2533a3
[root@docker ~]# docker run -tid --name os2 -h os2 centos
42218b44c003651da40e19ef9db328a5fc7ef583ef572d4d5dbdfbb54f710e92
[root@docker ~]# docker start db
db
[root@docker ~]# docker inspect db |grep -i ipaddr
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.5",
                    "IPAddress": "172.17.0.5",

虽然地址编程了0.5，但是依然不影响访问。

2.2 容器是如何通外网的
首先在宿主机上有一个docker0，这是一个虚拟交换机（linux bridge类型）。
brctl show
[root@docker ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.0242814d3a0a       no              vethba45877

1.容器通过虚拟网卡发送数据包（ip route 我要去哪里 docker0）
2.数据包通过veth pair 会发送到宿主机上的另外一个虚拟网卡（veth pire另一端）vethba45877
3.而vethba45877虚拟网卡，本身又是docker0交换机上的一个interface接口（brctl show）
4.最后流量达到docker0之后，通过宿主机上的iptables规则（iptables -t nat -L |grep 172），将所有来自于172.17.0.0/16流量进行伪装转换，执行SNAT，修改为外部网络接口的ip地址。

[root@docker ~]# docker run -tid --name web -h web -p 8080:80 nginx
外部就可以通过宿主机的8080端口访问到nginx了。因为底层做了DNAT
[root@docker ~]# iptables -t nat -nL
......

Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80

2.3 网络类型
默认共有3种本地网络驱动类型
bridge：桥接，docker0，当创建一个容器，默认就会在docker0上创建一个子接口，绑定容器网卡。为什么创建一个容器默认就连接到了docker0上？默认使用docker0
host：注意：不是仅主机，不是仅主机，不是仅主机!!!，容器直接复用宿主机所有网络资源，提升容器网络性能。host有且只能有一个。
null：如果创建容器选择了null类型，最终容器里面只有一个lo本地环回口，主要做研究测试，比如病毒程序。

如何自定义bridge类型的交换机
[root@docker ~]# docker network create -d bridge --subnet 192.168.66.0/24 abc
b6f2dca768a62bac6528143bf69755bb56ec237abb2dd9f3ea79e6ef538ea735
[root@docker ~]# docker network list
NETWORK ID     NAME      DRIVER    SCOPE
b6f2dca768a6   abc       bridge    local
b59cbe7ec5b7   bridge    bridge    local
09d555a8fa96   host      host      local
78695685e8bd   none      null      local

[root@docker ~]# docker run -tid --name os5 --network abc centos

如何定义host驱动类型呢？不可以，因为默认有且只能有一个
[root@docker ~]# docker network create -d host hostaaa
Error response from daemon: only one instance of "host" network is allowed

好处就是比如nginx，默认情况下需要进行端口映射才能访问，但是如果创建的时候采用host，不需要端口映射，直接访问宿主机即可。
[root@docker ~]# docker run -tid --name web --network host nginx

如何使用null类型创建容器
[root@docker ~]# docker run -tid --name os7 --network none centos

3.存储管理

3.1 临时层
默认容器里面的存储，属于容器存储层，它是临时的，会随着容器的删除而删除。
[root@docker ~]# docker run -tid --name os1 centos
6e1605f337d54dcf28f8f787aa7a5f32d7597c0214d73a7d918f977ae259e2f7
[root@docker ~]# docker exec -ti os1 /bin/bash
[root@6e1605f337d5 /]# ls
bin  dev  etc  home  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
[root@6e1605f337d5 /]# touch 111
[root@6e1605f337d5 /]# ls
111  bin  dev  etc  home  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
[root@6e1605f337d5 /]# exit
exit
[root@docker ~]# find / -name 111
/var/lib/docker/overlay2/d3624cb9dc9e6be2f687cb682eae886becf15e20369928c24138f63582f03d33/diff/111
/var/lib/docker/overlay2/d3624cb9dc9e6be2f687cb682eae886becf15e20369928c24138f63582f03d33/merged/111

diff相当于差分盘，保存发生变化的
merged合并的意思，是容器中整个文件系统的对外体现。
在底层diff或merged目录中修改的内容，同时也会反应到容器中。

当删除容器的时候，默认diff和merged中的数据也会随之删除，不保险。

3.2 持久化
这时候创建容器的时候，可以使用-v参数用于指定永久目录
-v /abc  volume：/abc 表示的是指定容器目录，它会在物理主机的固定目录/var/lib/docker/volumes下随机生成一个目录。
-v /host_abc:/container_abc volume: 前面宿主机目录，后面映射容器目录。

[root@docker ~]# docker run -tid --name os1 -v /abc centos
e4e646835fbd7b2d73b5b65289e1a1ae472a2e964aeda06a788c698418b6431f
[root@docker ~]# docker ps
CONTAINER ID   IMAGE     COMMAND       CREATED        STATUS        PORTS     NAMES
e4e646835fbd   centos    "/bin/bash"   1 second ago   Up 1 second             os1
[root@docker ~]# docker exec -it os1 /bin/bash
[root@e4e646835fbd /]# cd /abc/
[root@e4e646835fbd abc]# ls
[root@e4e646835fbd abc]# touch 666.txt
[root@e4e646835fbd abc]# exit
exit

[root@docker ~]# find / -name 666.txt
/var/lib/docker/volumes/e9951635cf584c2f50af2adf7a4e3fc01b8e4c9f7855ec8e8c006505d435664e/_data/666.txt

[root@docker ~]# docker rm -f e
e
[root@docker ~]# find / -name 666.txt
/var/lib/docker/volumes/e9951635cf584c2f50af2adf7a4e3fc01b8e4c9f7855ec8e8c006505d435664e/_data/666.txt

[root@docker mysql]# docker run -tid --name db -e MYSQL_ROOT_PASSWORD=redhat -v /mysql:/var/lib/mysql mysql

3.3 权限挂载
rw:读写权限，默认
ro：read only 只读权限。

应用场景：有个目录/文件，这个目录/文件内容不能让容器修改的。
[root@docker ~]# docker run -tid --name os1 -v /mysql:/test:ro centos

容器里面/test目录里面的文件，是无法修改。

4.Harbor
开源企业级私有镜像仓库

1）防火墙
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

2）安装docker
sed -e "s|^mirrorlist=|#mirrorlist=|g" -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.aliyun.com/centos-vault/8.4.2105|g" -i.bak /etc/yum.repos.d/CentOS-*.repo
yum install -y vim bash-completion net-tools tar wget yum-utils
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce

3）下载harbor离线包并解压
包含了很多脚本文件
[root@harbor ~]# tar -zxvf harbor-offline-installer-v2.12.1.tgz
[root@harbor ~]# cd harbor
[root@harbor harbor]# cp harbor.yml.tmpl harbor.yml
[root@harbor harbor]# vim harbor.yml

修改harbor.yml文件
修改hostname对应的ip地址，端口5500，并注释https所有参数。


4）修改docker.service
vim /usr/lib/systemd/system/docker.service

#在 ExecStart 参数后面添加 --insecure-registry=192.168.44.150:5500
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --insecure-registry=192.168.44.150:5500

#重启服务（重要，必须重启）
systemctl daemon-reload 
systemctl restart docker

5）执行准备脚本
[root@harbor harbor]# ./prepare

6）修改配置文件命令行（注意这一步主要看实际情况）

docker compose 它是一种针对于容器小型环境所使用的编排工具。

docker compose 分为两个版本 V1和V2
早期V1版本独立安装的，安装出来之后，命令：docker-compose
现在V2版本默认采用插件安装的，安装出来之后，命令：docker compose
现在V2版本能否自己手工采用独立安装呢？可以，怎么安装？不着急，等讲到compose的时候再讲。docker-compose

 #修改 common.sh
[root@docker harbor]# vim common.sh
#原 119 行 elif [[ $(docker-compose --version) =~ (([0-9]+)\.([0-9]+)([\.0-9]*)) ]]
#修改为 elif [[ $(docker compose version) =~ (([0-9]+)\.([0-9]+)([\.0-9]*)) ]]

#修改 install.sh
[root@docker harbor]# vim install.sh
#原 26 行 DOCKER_COMPOSE=docker-compose
#修改为 DOCKER_COMPOSE="docker compose"

7）执行安装配置
[root@harbor harbor]# ./install.sh

8）配置推送及拉取参考博文
https://blog.51cto.com/cloudcs/11778828
