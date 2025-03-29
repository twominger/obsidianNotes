相关术语：[[Docker]] , [[container]], [[namespace]]
相关知识：[[Docker/虚拟化技术概述|虚拟化技术概述]]，

# 引入
## 计算资源演进过程
1. **物理服务器**  
	优点：性能极佳  
	缺点：价格高，资源利用率不足，操作维护麻烦，没有自动弹性伸缩，最头疼：开发（开发服务器/测试服务器/生产服务器），环境无法严格统一。

2. **虚拟机**  
	优点：轻量级服务器、虚拟化平台高可用、系统级别资源隔离、资源充分利用  
	缺点：VMM hypervisor 性能损耗，启动时间比较长，应用调用链比较长（linux kernel --> vmm --> vm）

需求：我只想要一个mysql，要一个nginx应用，出现了一种更加比虚拟化还要轻量级的一种，虚拟化技术：容器技术

不管是物理服务器，还是虚拟机，它们最终都会运行一个完整的OS：  
一个完整OS包括两个部分：内核空间/用户空间  
容器本身底层不是一个完整的OS：容器只包含了用户空间，没有内核空间  
虚拟机做系统/资源/用户级别的隔离。

3. **容器**  
	优点：启动极快，可达到亚秒级别；应用之间的隔离；不需要配置网络；一次模板，跨平台多次使用，保障所有的平台环境完全一致。  
	缺点：可控制性不强，体现在应用运行，容器运行，应用如果关闭，则容器关闭。和传统的物理服务器及虚拟机管理方式是不同的，大家不要拿着传统的思维方式去管理容器。

物理服务器或虚拟机，都可以进行单独管理。但是容器不能有单独管理的这种思维。  
思维方式转变：现在讲docker容器，未来生产不会是以单个容器去管理和部署，有成百上千，成千上万个容器，管理容器是要通过容器管理平台/容器编排工具，进行管理的。现在讲容器的目的是什么？目的是为了引出后续的编排工具。
## 容器如何实现虚拟化
- 虚拟化是通过 hypervisor 进行硬件的模拟，从而实现虚拟化
- 容器是容器引擎通过 [[namespace]] 和 [[Cgroup]] 对应用进行欺骗，从而实现虚拟化
	- namespace 实现资源隔离，Cgroup 实现资源限制
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319205520393.png)
## 容器对比虚拟机有哪些优势
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319210359171.png)
## Docker 与 k8s 商业之争

- 2013年之前，各个厂商PaaS平台，它们的应用打包机制都不一样。openshift/cloudify/cloudFoundry

- 2013年，有一家公司 DotCloud，开源一个产品 Docker，一经开源，风靡全球。年底，更改公司名称Docker CoreOS（钢铁理工直男）甘愿为docker做嫁衣，开发一个操作系统 CoreOS Container Linux，目标为容器而生。  
coreOS推出了几个开源项目：k8s默认用的KV键值存储数据库 etcd；k8s网络插件CNI标准；k8s早期网络插件flannel（生产环境不用） （现在常用 clium,calico） 
coreOS本身想法：docker 啊，你就老老实实跟我，你好好做容器产品。其他事情（容器编排、集群管理系统、镜像等）不要参与。
- 2014 由于利益冲突导致割裂。coreOS 推出自家的容器产品 Rocket（rkt），但是这个容器产品只包含了**容器运行时**，没有其他管理功能，故意的。  coreOS致力于打造一个单纯的生态环境。

随着容器的火爆，基于容器业务越来越多，容器数量也越来越大。容器怎么管理就成了一个问题  
- 当年docker已经有自己的容器管理平台了，2014年谷歌找到Docker，打算把自己的容器编排工具捐赠给docker。Docker 不要。

- 2014年6月10日，谷歌直接把自己在内部Borg系统（集群管理系统），以开源的方式托管在了全球最大的代码托管平台 github上，起名叫kubernetes=k8s k3s(轻量级的 k8s,用于学术等)
凭借k8s先进的容器编排理念，世界各大厂商都来加入，IBM/微软/红帽/Docker等。  

- 2015年的时候，谷歌还投资coreOS，专门为k8s开发了一个企业级平台。

截至到2015年，世界上容器领域的编排软件呈现三足鼎立：谷歌**k8s/Docker(compose/swarm/machine)/Apache Mesos Marathon**

最终分为了谷歌派系和Docker派系，之后慢慢从容器及编排技术领域之争，演变到了标准之战。

- 2015年6月份，docker联合Linux基金会，成立了一个组织，OCP（open container project）,后改名 OCI Initiative 开放容器计划。  

OCI致力于打造容器运行时标准。  
docker 把自己的libcontainer 捐赠给了OCI组织，OCI组织对其进行了完善并重命名 runc，runc又不断的完善者标准。

- 2015年7月份，谷歌联合20多家公司直接成了一个组织，CNCF云原生计算基金会（属于Linux基金会一部分），  
CNCF致力于打造容器编排标准。  
谷歌把自己的k8s捐赠给了CNCF，也是从CNCF毕业的第一个项目。

- 2016年开始，CNCF涉及开源想多达近200个，全球开发者贡献者达到近20万，遍布全球近200个国家。

OCI/CRI/CNI/CSI/runc/libcontainer/contaierd/CNCF......

从现在开始，把自己的角色定位成一位老师，讲述者。

docker/podman/containerd/rkt/isula...

# 概念
## 什么是 Docker?
Docker 是一个开源的应用容器引擎
容器引擎还有：docker/podman/containerd/rkt/isula...

## Docker 原理
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319225224313.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319214459321.png)

[Docker原理（图解+秒懂+史上最全）-CSDN博客](https://blog.csdn.net/crazymakercircle/article/details/120747767)
[太全了｜万字详解Docker架构原理、功能及使用 - 知乎](https://zhuanlan.zhihu.com/p/269485082)

## Docker 技术架构
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250319230505508.png)
三个部分：客户端、服务端（docker engine）、镜像仓库registry  
理解容器和镜像关系：  
你如果想要创建容器，前提是必须得有镜像。镜像是容器的载体。

docker pull 直接通过daemon到默认registry仓库中拉取镜像到本地  
docker run 直接通过本地镜像创建一个容器并运行它，如果本地没有这个容器所需的镜像怎么办？docker run会自动先去registry拉取到本地，然后再通过镜像创建容器。



