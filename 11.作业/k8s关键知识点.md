# k8s 组件及架构：
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250224170818373.png)
k8s 架构分为两个平面：控制平面/数据平面
- etcd：Key-Value 键值存储系统（存储数据库），存储集群所有信息（用户提交的描述信息及当前集群的状态信息）
- kube-api-server: 集群的访问入口，接收外部请求处理的，而且所有的组件都需要与它交互
- kube-scheduler: 集群调度器，通过计算将对象资源绑定给某个节点
- kube-controller-manager: 保证集群中的各种资源实际状态（status）与用户定义的期望状态（spec）一致。

- kubelet： 是 k8s 数据节点上的守护进程，负责容器管理、健康检查、信息状态收集上报。
- kube-proxy: 负载均衡和网络代理的组件，管理者服务和容器之间的流量转发。两种转发模式：iptables/ipvs
## 创建一个 pod 的流程：

用户提交创建 `Pod` 请求时，该请求首先会发送到 `kube-apiserver`。
`apiserver` 会将 `pod` 的信息存储到 `etcd` 中。
kube-scheduler 周期性向 api-server 进行询问，是否存在要调度的资源；
api-server 查询 etcd，将 `pod` 的定义和集群状态信息给到 kube-scheduler；
kube-scheduler会根据 `pod` 的需求和集群的当前状态来选择一个最合适的节点来运行该 `pod`, 并将最终的决策信息返回给 api-server 保存到 `etcd` 中。
`Kubelet` 会定期从 `kube-apiserver` 查询它负责的 `pod` 信息。
当发现有新的 `pod` 需要在其节点上运行时，就会根据 apiserver 提供的 pod 信息创建 `pod` 的容器, 
kubelet-->CRI-->containerd-->container-shim-->runc-->namespace/cgroup

# pod 的重启策略
##  `Always`: 
当前 pod 无论是正常退出，还是非正常退出，全部总是执行反复重启。
##  `Never`: 
不管你是正常退出，还是非正常退出，全都不重启。
##  `OnFailuer`: 
正常退出不重启；非正常退出再重启。

# pod dnsPolicy
##  `None`：
无 DNS 配置。使用该策略后，Pod 会使用其 dnsConfig 字段所提供的 DNS 设置
##  `Default`：
使用默认配置。Pod 中，默认是继承宿主机的 DNS 配置
##  `ClusterFirstWithHostNet`：
对于以 hostNetwork 方式运行的 Pod，应设置为此策略
## `ClusterFirst`：
默认配置。使用集群的 DNS 服务器，即 coredns
# pod 有哪些状态

- Pending           等待中
- Running           运行中
- Succeeded      正常终止
- Failed              异常停止
- Unkonwn         未知状态

# pod 资源限制
`request` 和 `limit`

# pod 探针
## `livenessprobe `:存活探针
一旦检测到，比如丢失了文件、端口等，那么存活探针就会直接重启该 pod 来尝试解决问题。

## `readinessprobe`:就绪探针
探测到问题后，不会重启，会显示未就绪，通过 svc，不要将流量路由到该 pod 上。

## `startupProbe`:启动探针
是为了保证pod的应用能够完整的启动，一旦检测到完全启动，启动探针退出，启动探针一旦探测成功，就退出了，不会再次运行了，之后的探测工作就交给了存活探针和就绪探针。

# 生命周期钩子 
poststart/prestop

# pod 调度
## pod cordon（警戒线）
cordon 相当于给节点拉起一条警戒线。
主要是为了临时维护或更新某些操作，某段时间内不允许再往该节点上调度 pod。对于当前节点上已经存在且运行的 pod 不受影响。
## pod drain（警戒线+驱逐）
drain 这个操作包含了两个动作（cordon-->evicted）
这里的驱逐 evicted 动作，只能在控制器中，例如 deployment 中看到效果，如果 pod 是手工创建的，看不到效果（效果等同于删除）。对于当前节点上已存在且运行的 pod 会进行删除/驱逐。
## pod taint (污点)

# k8s 存储管理
本地存储：
emptyDir/hostPath
网络存储：
NFS，SAN 等
持久性存储（重点）：
PV/PVC

# 工作负载状态
无状态工作负载：deployment
有状态工作负载：statefulset
# 控制器有哪些 ：
- deployment
	- replicaSet 控制副本数
- statefulset 
- daemonset 守护进程集。
- job 单次任务（普通任务）
- cronjob 循环任务（定时任务）
# SVC 服务发布
## 1 . ClusterIP (含无头 headless 服务)
默认创建的 SVC，采用的默认类型 clusterip，clusterip 是一个虚拟 ip（不是真实存在的），提供给集群内部组件或者内部 pod 访问，不能对外访问。
## 2 . NodePort
## 3 . LoadBalancer
## 4 . ExternalName

## 5 . Ingress（单独）
通过域名（做 7 层负载均衡）来实现访问后端不同 pod（看到不同内容）

面试的时候有个很大的坑。ingress-controller 它根据路由规则，通过 svc 获取 ep 地址，直接将流量传递给后端的对应 pod，流量不再经过 SVC。

# 身份认证
kubeconfig
静态 token

