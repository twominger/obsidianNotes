内容回顾
1.容器管理
2.容器网络
3.容器存储
4.Harbor开源企业级的Registry仓库
----
1.了解Harbor组件（害怕面试的时候问）

代理层
nginx：该代理将来自浏览器、docker clients的请求转发到后端服务上。

功能层
harbor-core：Harbor 的核心组件，负责处理所有的 API 请求、身份验证、权限管理等。
harbor-portal：用户界面，允许用户通过浏览器管理镜像、项目和用户。
harbor-jobservice：主要用于镜像复制，本地镜像可以被同步到远程Harbor实例上。
registry：底层的 Docker Registry，用于实际存储容器镜像。
registryctl：底层的 Docker Registry 控制组件，控制底层镜像清理。

数据层
redis：缓存数据库
harbor-db：存储harbor信息的数据库 postgresql（PG）
harbor-log：运行rsyslogd的容器，主要用于收集其他容器的日志。

2.资源限制
2.1限制内存
[root@docker ~]# docker run -tid --name os3 -m 128m centos

[root@docker ~]# docker stats --no-stream
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O        PIDS
260bc17b7a4c   os3       99.06%    103.7MiB / 128MiB     81.01%    866B / 0B     20.3MB / 504kB   3
458c2845c659   os2       0.00%     1.551MiB / 7.749GiB   0.02%     866B / 0B     0B / 0B          1
1da5b80d38a6   os1       0.00%     1.547MiB / 7.749GiB   0.02%     1.12kB / 0B   0B / 0B          1

[root@docker ~]# docker cp memload-7.0-1.r29766.x86_64.rpm os3:/
Successfully copied 8.7kB to os3:/
[root@docker ~]# docker exec -ti os3 /bin/bash
[root@260bc17b7a4c /]# ls
bin  etc   lib    lost+found  memload-7.0-1.r29766.x86_64.rpm  opt   root  sbin  sys  usr
dev  home  lib64  media       mnt                              proc  run   srv   tmp  var
[root@260bc17b7a4c /]# rpm -ivh memload-7.0-1.r29766.x86_64.rpm
Verifying...                          ################################# [100%]
Preparing...                          ################################# [100%]
Updating / installing...
   1:memload-7.0-1.r29766             ################################# [100%]
[root@260bc17b7a4c /]#
[root@260bc17b7a4c /]# memload 100
Attempting to allocate 100 Mebibytes of resident memory...
^C
[root@260bc17b7a4c /]# memload 256
Attempting to allocate 256 Mebibytes of resident memory...
Killed
[root@260bc17b7a4c /]#

2.2 限制cpu（限制cpu跑在某个核心上）
避免让他频繁进行上下文（烧水、洗菜）切换，提升性能
[root@docker ~]# docker exec -ti os2 /bin/bash
[root@458c2845c659 /]# cat /dev/zero > /dev/null &
[1] 29
[root@458c2845c659 /]# cat /dev/zero > /dev/null &
[2] 30
[root@458c2845c659 /]# cat /dev/zero > /dev/null &
[3] 31
[root@458c2845c659 /]# cat /dev/zero > /dev/null &
[4] 32
[root@458c2845c659 /]# cat /dev/zero > /dev/null &
[5] 33
[root@docker ~]# ps mo pid,comm,psr $(pgrep cat)
    PID COMMAND         PSR
 808733 cat               -
      - -                 0
 808734 cat               -
      - -                 1
 808737 cat               -
      - -                 1
 808743 cat               -
      - -                 1
 808744 cat               -
      - -                 1

在创建容器的时候，直接限制cpus，让它跑在固定的核心上。
[root@docker ~]# docker run -tid --name os2 --cpuset-cpus 0 centos
672fa3315e4710c7655aedf595cff3493cc8e1c4fa5f15c87164c99b3920445b
[root@docker ~]# docker exec -ti os2 /bin/bash
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[1] 29
[root@672fa3315e47 /]#
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[2] 30
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[3] 31
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[4] 32
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[5] 33
[root@672fa3315e47 /]# cat /dev/zero > /dev/null &
[6] 34
[root@672fa3315e47 /]# exit
exit
[root@docker ~]# ps mo pid,comm,psr $(pgrep cat)
    PID COMMAND         PSR
 809970 cat               -
      - -                 0
 809978 cat               -
      - -                 0
 809979 cat               -
      - -                 0
 809987 cat               -
      - -                 0
 809988 cat               -
      - -                 0
 809989 cat               -
      - -                 0

3.编排
docker 编排组件：docker compose/docker swarm
docker compose 适用于小型自动化部署环境。

V1和V2两个版本
V1：之前以独立的部署方式进行部署 docker-compose
V2：现在新版本的docker-ce 默认不再是以独立的方式部署，而是以插件的方式部署 docker compose

V2能不能进行独立部署？独立二进制方式部署
https://github.com/docker/compose/tags

[root@docker ~]# mv docker-compose-linux-x86_64 /usr/bin/docker-compose
[root@docker ~]# chmod +x /usr/bin/docker-compose
[root@docker ~]#
[root@docker ~]# docker-compose

也可是使用默认插件安装的命令
[root@docker ~]# docker compose

比如之前搭建博客两条命令以docker compose的yaml文件形式写出来

docker run -tid --name db -h db -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_DATABASE=wordpress mysql
docker run -tid --name web -h web --link db:aliasdb -e WORDPRESS_DB_HOST=aliasdb -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=redhat -e WORDPRESS_DB_NAME=wordpress -p 5000:80 wordpress

注意：在使用docker compose或者docker-compose 命令去批量编排管理容器的时候，对应的yaml文件名称分为两种：
1）标准名称：docker-compose.yaml
2）非标准名称：abc.yaml  bbb.yaml 只不过，如果不是标准名称，在使用docker compose或者docker-compose 管理的时候，需要多带一个参数 -f 指定file

yaml格式
1）同级标题左对齐
2）缩进只能用空格

cat <<"EOF" > docker-compose.yaml
services:
  blog:
    image: wordpress:latest
    restart: always
    links:
      - db:aliasdb
    ports:
      - "5000:80"
    environment:
      - WORDPRESS_DB_HOST=aliasdb
      - WORDPRESS_DB_USER=root
      - WORDPRESS_DB_PASSWORD=rootroot
      - WORDPRESS_DB_NAME=wordpress

  db:
    image: mysql:latest
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=rootroot
      - MYSQL_DATABASE=wordpress
EOF

启动容器，两个命令随便都可以
[root@docker ~]# docker compose up -d
[root@docker ~]# docker-compose up -d

停止并删除容器
[root@docker ~]# docker compose down

停止容器
[root@docker ~]# docker compose stop
[root@docker ~]# docker compose start

重启容器
[root@docker ~]# docker compose restart

[root@docker ~]# ls
aaa.yaml

[root@docker ~]# docker compose up -d
no configuration file provided: not found

没找到标准名称叫 docker-compose.yaml的文件
[root@docker ~]# docker compose -f aaa.yaml up -d
[+] Running 3/3
 ✔ Network root_default   Created                                                                                  0.1s
 ✔ Container root-db-1    Started                                                                                  0.3s
 ✔ Container root-blog-1  Started                                                                                  0.6s

[root@docker ~]# docker compose -f aaa.yaml down
[+] Running 3/3
 ✔ Container root-blog-1  Removed                                                                                  1.2s
 ✔ Container root-db-1    Removed                                                                                  1.0s
 ✔ Network root_default   Removed                                                                                  0.1s

4.自定义镜像dockerfile（压轴）

从0开始可以吗？可以，但是没必要。

4.1 了解镜像分层

镜像一旦被创建，这个镜像（已经封装的部分）是无法被修改的，镜像是分层的。
如果想要去修改添加，一定是在原有的镜像基础之上进行的构建。
而且，不管你添加多少层，镜像层永远都是只读层。
创建容器无非是在镜像只读层的最上方，创建了一层容器读写层。
通过联合文件系统，将镜像只读层和容器读写层一并挂载到当前文件系统中，不管镜像多少层，最终给用户看到的就是一个文件系统。里面包含了所有镜像层的所有内容。

这种文件系统技术叫 UnionFS 联合文件系统：
1.aufs: 容器读写层修改数据，它会一层一层去查找镜像只读层，如果层数嵌套太多，那么寻址速度就会很慢
2.overlayfs(overlay2):容器读写层修改数据，因为底层的每一个上层都会有下一层的硬链接，所以容器读写层看到的所有数据，都可以在最上层的镜像只读层找到。
3.devicemapper：红帽找docker联合开发的一个联合文件系统，性能不好。

4.2 dockerfile原理
看视频看图
核心：编写dockerfile文件

4.3 了解dockerfile文件结构
[root@docker ~]# docker run -tid --name os1 centos
e470dc5e1691fd8ad172b02d731a7ac720030786b8653477bac102ead27878cc

[root@docker ~]# vim dockerfile
[root@docker ~]# cat dockerfile
FROM centos
MAINTAINER tianhairui

RUN sed -e "s|^mirrorlist=|#mirrorlist=|g" -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.aliyun.com/centos-vault/8.4.2105|g" -i.bak /etc/yum.repos.d/CentOS-*.repo
RUN yum install -y vim net-tools bash-completion
RUN echo 666 > index.html

CMD ["/bin/bash"]


----
第一部分：添加基础镜像，FROM不可以重复出现的
FROM centos

第二部分：注释注解信息，增加一个元数据层
MAINTAINER tianhairui
LABEL author="tianhairui" \
      aaa="bbb"
      ccc="ddd"

第三部分：构建镜像，可以重复出现，这里出现的RUN/ADD/COPY等关键字，出现一次，增加一层镜像层
RUN sed -e "s|^mirrorlist=|#mirrorlist=|g" -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.aliyun.com/centos-vault/8.4.2105|g" -i.bak /etc/yum.repos.d/CentOS-*.repo
RUN yum install -y vim net-tools bash-completion
RUN echo 666 > index.html

RUN sed -e "s|^mirrorlist=|#mirrorlist=|g" -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.aliyun.com/centos-vault/8.4.2105|g" -i.bak /etc/yum.repos.d/CentOS-*.repo && yum install -y vim net-tools bash-completion && echo 666 > index.htm

第四部分：指定容器运行的任务
CMD ["/bin/bash"]
ENTRYPOINT ["xxx.sh"]
----

4.4 自定义镜像

1）通过centos 构建自己的nginx镜像

[root@docker ~]# vim dockerfile1
[root@docker ~]# cat dockerfile1
FROM centos:yum

LABEL author="tianlaoshi"

RUN yum install -y nginx

CMD ["nginx","-g","daemon off;"]
[root@docker ~]#
[root@docker ~]#
[root@docker ~]# docker build -t centos:nginx -f dockerfile1 .

注意：CMD这个里面指定的任务，是可以随时通过其他任务进行覆盖的。

2）添加一些文件
[root@docker ~]# vim dockerfile2
[root@docker ~]# cat dockerfile2
FROM centos:nginx

LABEL author="tianlaoshi"

ADD index.html /usr/share/nginx/html/

COPY index.html /tmp/

[root@docker ~]# docker history centos:nginx
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
a77dc8ad8442   9 minutes ago    CMD ["nginx" "-g" "daemon off;"]                0B        buildkit.dockerfile.v0
<missing>      9 minutes ago    RUN /bin/sh -c yum install -y nginx # buildk…   79.8MB    buildkit.dockerfile.v0
<missing>      9 minutes ago    LABEL author=tianlaoshi                         0B        buildkit.dockerfile.v0
<missing>      23 minutes ago   CMD ["/bin/bash"]                               0B        buildkit.dockerfile.v0
<missing>      23 minutes ago   RUN /bin/sh -c echo 666 > index.html # build…   4B        buildkit.dockerfile.v0
<missing>      23 minutes ago   RUN /bin/sh -c yum install -y vim net-tools …   77.2MB    buildkit.dockerfile.v0
<missing>      24 minutes ago   RUN /bin/sh -c sed -e "s|^mirrorlist=|#mirro…   17.6kB    buildkit.dockerfile.v0
<missing>      24 minutes ago   MAINTAINER tianhairui                           0B        buildkit.dockerfile.v0
<missing>      3 years ago      /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      3 years ago      /bin/sh -c #(nop)  LABEL org.label-schema.sc…   0B
<missing>      3 years ago      /bin/sh -c #(nop) ADD file:805cb5e15fb6e0bb0…   231MB
[root@docker ~]# docker build -t centos:nginx666 -f dockerfile2 .

add 和copy 区别
[root@docker ~]# vim dockerfile3
[root@docker ~]# cat dockerfile3
FROM centos:nginx

LABEL author="tianlaoshi"

ADD abc.tar.gz /mnt/

COPY abc.tar.gz /tmp/

[root@docker ~]# docker build -t centos:addcopy -f dockerfile3 .

add 可以自动解压压缩包（.tar/.tar.gz/.tgz/.tar.bz2/.tar.xz），但是不支持.zip
copy 不会自动解压

3） WORKDIR
在全局进入到某个目录里面
FROM centos:nginx

LABEL author="tianlaoshi"

#ADD abc.tar.gz /mnt/
WORKDIR /tmp

#COPY abc.tar.gz /tmp/

RUN tar -zxvf abc.tar.gz

4）USER
默认登录的用户
[root@docker ~]# vim dockerfile4
[root@docker ~]# cat dockerfile4
FROM centos:yum

RUN yum install -y passwd  openssh-clients openssh-server
RUN useradd tom
RUN echo 'redhat' |passwd --stdin tom
RUN echo 'redhat' |passwd --stdin root
USER tom
[root@docker ~]# docker build -t centos:tom -f dockerfile4 .
[+] Building 3.6s (9/9) FINISHED                                                                                     docker:default
 => [internal] load build definition from dockerfile4                                                                          0.0s
 => => transferring dockerfile: 277B                                                                                           0.0s
 => [internal] load metadata for docker.io/library/centos:yum                                                                  0.0s
 => [internal] load .dockerignore                                                                                              0.0s
 => => transferring context: 2B                                                                                                0.0s
 => CACHED [1/5] FROM docker.io/library/centos:yum                                                                             0.0s
 => [2/5] RUN yum install -y passwd  openssh-clients openssh-server                                                            2.8s
 => [3/5] RUN useradd tom                                                                                                      0.2s
 => [4/5] RUN echo 'redhat' |passwd --stdin tom                                                                                0.2s
 => [5/5] RUN echo 'redhat' |passwd --stdin root                                                                               0.2s
 => exporting to image                                                                                                         0.1s
 => => exporting layers                                                                                                        0.1s
 => => writing image sha256:ac8d2703cad75c25c3cd50daaa6ae4d7712bbcaaac9825a339f5ff272906e32d                                   0.0s
 => => naming to docker.io/library/centos:tom                                                                                  0.0s
[root@docker ~]#
[root@docker ~]# docker run -tid --name os3 centos:tom
02187df3ce965c450a48cff3efca71004d7bce22b547960350c9a8e1330d4d1b
[root@docker ~]# docker exec -ti os3 /bin/bash
[tom@02187df3ce96 /]$ su - root
Password:
[root@02187df3ce96 ~]# exit
logout
[tom@02187df3ce96 /]$ exit
exit

5）ENV
环境变量
FROM centos:nginx

LABEL author="tianlaoshi"

ENV AAA="1111" \
    BBB="2222"

未来创建的所有容器，执行 echo $AAA

6) EXPOSE
暴露端口
FROM centos:nginx

LABEL author="tianlaoshi"

ENV AAA="1111" \
    BBB="2222"

EXPOSE 80 443

未来通过history可以让别人知道容器默认端口是什么，注意，这个仅仅就是一个注释，它不会自动映射。

如果你的镜像里面没有带 EXPOSE 这个关键字，那么未来创建容器的时候，手工进行端口暴露通过 -p 5500:80
如果你的镜像里面带了 EXPOSE 这个关键字，那么未来创建容器的时候，可以直接通过 -P 参数自动暴露（随机端口）

[root@docker ~]# docker run -tid --name os4 -P nginx:latest
[root@docker ~]# docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                     NAMES
c10c13b3afdc   nginx:latest      "/docker-entrypoint.…"   3 seconds ago    Up 3 seconds    0.0.0.0:32768->80/tcp, :::32768->80/tcp   os4

7） VOLUME

FROM centos:nginx

LABEL author="tianlaoshi"

ENV AAA="1111" \
    BBB="2222"

EXPOSE 80 443

VOLUME /host_aaa /container_bbb

如果你的镜像里面没有带 VOLUME 这个关键字，那么未来创建容器的时候，手工进行存储卷映射 -v /aaa:/bbb
如果你的镜像里面带了 VOLUME 这个关键字，那么未来创建容器的时候，不需要带-v参数，直接创建出来。

8）ENTRYPOINT

Entrypoint 这个关键字，一般会指定一个脚本
注意：
1.如果CMD和ENTRYPOINT同时存在，那么CMD可作为参数传递给ENTRYPOINT使用。
2.CMD指定的任务，是可以被手工覆盖的。但是 ENTRYPOINT里面的任务不可以被覆盖。


vim dockerfile
-------
FROM centos:yum

LABEL author="tianlaoshi"

ENV AAA="1111" \
    BBB="2222"

EXPOSE 80 443

RUN yum install -y nginx

VOLUME /host_aaa /container_bbb

CMD ["nginx","-g","daemon off;"]

ENTRYPOINT ["/abc.sh"]


/abc.sh
------
if [ -z "$abc" ];then
    abc="666"
fi

echo $abc > /usr/share/nginx/html/index.html
exec "$@"

$@ 接收所有参数
最后一条命令就相当于

exec "nginx -g daemon off;"

假如这个镜像 centos:888

如果 docker run -tid --name os1 centos:888 sleep 3600

启动容器，做一些前置初始化工作。