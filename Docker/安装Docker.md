1. 克隆一台 linux，参照[[linux/制作虚拟机模板|制作虚拟机模板]]。
2. 修改主机名和 IP 地址。
3. 配置 yum 源，参照 [[linux/yum源|yum源]]。
4. 安装基础软件包（可以在模板中提前配置好）
```shell
yum install -y vim bash-completion net-tools tar wget yum-utils
```
5. 关闭防火墙和 SELinux,参照 [[linux/SELinux#如何关闭 SELinux|SELinux]]。
6. 安装 Docker
> [! Docker版本]
> 2017年3月份之前，1.10/11/12/13....  
> 2017年3月份之后，docker公司为了满足不同的业务需求，docker分为两个版本：Docker-ce/Docker-ee  
> 
> docker-ce：开源社区版，个人免费使用  
> docker-ee：企业版，企业付费客户使用 2020年因国际政治原因，一度在国内被限制使用。
> 
> docker-ce版本通常3部分构成：V3
> 主版本号：19/20/21...重大更新  
> 次版本号：01/02/03...添加功能或新特性  
> 修复版本号：1/2/3....修复一些bug或小改进

现在yum源中是没有关于docker-ce的源。
- 在[阿里云镜像站](https://developer.aliyun.com/mirror/) 搜索 `docker-ce` 通过 `yum-utils` 添加 docker-ce 源
```shell
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```
- 查看docker-ce版本
```shell
yum list docker-ce --showduplicate |sort -r
```
- 安装docker-ce
```shell
yum install docker-ce # 默认安装最新版  
yum install docker-ce-23.0.6 docker-ce-cli-23.0.6 # 安装指定版本
```
- 启动服务
```shell
systemctl enable docker --now
```
- 查看服务状态
```shell
systemctl status docker
```
- 查看 docker 版本
```shell
docker -v
```




