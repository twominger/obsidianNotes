负载均衡器：



关系型数据库：
- mysql

非关系型数据库：
- 文档型数据库
	- mongodb
- 内存型数据库：
	- radis
- 数据库缓存：
	- memcached

应用缓存服务器：
- squid
- varnish
- nginx(最初是邮件代理服务器)

- cdn(内容分发网络)

大单体应用架构：
- cdn - 源站负载均衡器 - （应用缓存） - 应用服务 - 数据库缓存 - 数据库


单体应用 - 前后端分离

前端应用
后端应用

SOA(面向服务的体系架构)

微服务
按接口数量 / 数据相关性

sla xiaolv chengben
sla 稳定性




kubenetes

- istio
- 服务网格

注册中心：
- etcd
- zookeeper

api 网关：
- apisix

配置中心：
- nacos
- etcd

消息队列：
- rabbitmq
- kafka


限流

熔断



sre 的核心：
- 确保所有的组件五单点故障
	- 确保所有中间件都是集群模型
	- 确保所有的应用至少两副本部署
	- 确保负载均衡器至少是高可用模式
	- ...........
- 可观测性的三板斧：
	- 监控
		- peometheus
		- victoriaMetrics
		- thanos
	- 日志
		* ELK: filebeat + logstash + elasticsearch + kibana
		* PLG: promtail + loki + grafana
		- victoriaLogs
	- 链路追踪
		* opentrace + opensearch + jaeger
		* skywalking/zipkin/pinpoint

* 混沌工程（故障注入）

devops: 
- 自动化
- 标准化
- 规范化

中间件的批量部署：
- ansible
- saltstack

公有云批量创建资源：
* terraform

应用发布：
* gitlab
* jenkins

基础平台：
- openstack
- kubernetes
- 裸机管理：bmc

存储：

- ceph 
	- 文件系统
		- cephfs
		- nfs
	- 块设备
	- 对象存储
- minio

辅助系统：
- 项目管理：禅道
- 知识库：confluence