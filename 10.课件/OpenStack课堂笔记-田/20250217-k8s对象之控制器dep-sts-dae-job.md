# deployment
## 滚动更新
kubectl set image deployment web1 nginx=nginx:1.26.4

  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate

这两个参数是可以单独使用的。而且他们的值有两种类型（百分比/具体的数值）

maxSurge: 最大浪涌
maxUnavailable: 最大不可用数

maxSurge特性：先创建新的pod，再终止删除旧pod

  strategy:
    rollingUpdate:
      maxSurge: 1  当更新镜像的时候，更新的过程中，最多新增多少个。
    type: RollingUpdate

maxUnavailable特性：先删除除旧pod，再创建新pod

  strategy:
    rollingUpdate:
      maxUnavailable: 1  当更新镜像的时候，更新的过程中，最多有多少个不可用。
    type: RollingUpdate

放在一起
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 5
    type: RollingUpdate

例如：现在系统中有10个pod，当更新镜像的时候，首先会看到新创建了2个pod，pod总数12个，另外会看到其中会有5个pod处于terminating

如果使用百分比，这里面有个问题。假如现在有10个pod，问：每次创建多少个？每次终止多少个？
  strategy:
    rollingUpdate:
      maxSurge: 25% 向上取整，新增3个
      maxUnavailable: 25% 向下取整，终止2个
    type: RollingUpdate

# rs（ReplicaSet）
一般情况下，rs不会单独使用，它是配合 deployment 来使用的。
在deployment里面，定义一个参数replicas=5，当执行创建deployment的时候，就会自动的创建一个RS，自动创建的这个rs（k8s集群中的一个对象）就是用来管理deployment里面的那个副本数的。

[root@master ~]# kubectl get rs
NAME                                DESIRED   CURRENT   READY   AGE
nfs-client-provisioner-5c578b7757   1         1         1       29h
web1-5fd8df5b8                      0         0         0       26h
web1-6bff9977d                      0         0         0       26h
web1-6d89b5b4ff                     0         0         0       26h
web1-748d6bfb7f                     0         0         0       26h
web1-7876fc6749                     0         0         0       26h
web1-79c54c7567                     0         0         0       26h
web1-7b89bd8dc7                     10        10        10      5m29s
web1-7bf74d9565                     0         0         0       26h
web1-7c9bff7f66                     0         0         0       6m31s
web1-8d4489d6c                      0         0         0       26h
web1-c4c56dd65                      0         0         0       27h

[root@master ~]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          28h
web1-7b89bd8dc7-6c594                     1/1     Running   0          5m44s
web1-7b89bd8dc7-8gflx                     1/1     Running   0          5m41s
web1-7b89bd8dc7-8nq4m                     1/1     Running   0          5m38s
web1-7b89bd8dc7-dfrms                     1/1     Running   0          5m44s
web1-7b89bd8dc7-fj7nz                     1/1     Running   0          5m44s
web1-7b89bd8dc7-mlrj8                     1/1     Running   0          5m44s
web1-7b89bd8dc7-pbdr7                     1/1     Running   0          5m44s
web1-7b89bd8dc7-qjrf2                     1/1     Running   0          5m39s
web1-7b89bd8dc7-rkkqb                     1/1     Running   0          5m39s
web1-7b89bd8dc7-xhcnq                     1/1     Running   0          5m40s

# 小穿插（补充nodeName）
cordon/drain/taint 关于pod调度

https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/assign-pod-node/

```shell
[root@master ~]# vim pod1.yaml
[root@master ~]# cat pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  nodeName: master
  containers:
  - image: nginx
    name: pod1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

`nodeName: master`: 忽略污点，直接在 master 上调度


# StatefulSet

https://support.huaweicloud.com/basics-cce/kubernetes_0015.html

无状态工作负载：deployment
有状态工作负载：statefulset

无状态工作负载：deployment
deployment管理的所有pod副本，是没有主次角色之分，功能之分的。他们的作用完全一模一样。场景：特别适合业务前端，nginx/lvs在前端做负载的这些应用，没有数据持久化的。pod的名字是随机的。

有状态工作负载：statefulset
sts管理的pod，是有主次角色之分的。他们的作用是不一样的。场景：类似于mysql（主备）、redis等后端应用，需要做数据持久化的。pod的名字是固定的。

Headless Service 无头服务，配合sts来使用的。

1.在sts控制器管理的pod中，是有状态角色之分的，不需要svc的ip地址做负载均衡（kube-proxy）
2.在sts控制器管理的pod中，直接使用主库的pod 的 ip地址访问不行吗？有可能发生变化。
3.在sts控制器管理的pod中，连接主库需要找到一个固定的连接标识，这个标识就是一个域名，称之为“Headless service”无头服务（本质上还是一个service，类型为ClusterIP，和普通的clusterIP类型不同的是，它没有ip地址）

ClusterIP：它是给k8s集群内部提供访问入库的一个IP地址（虚拟ip，虚拟出来的，不是真实的）。外部是无法使用和访问。

1.创建一个headless service
```shell
apiVersion: v1
kind: Service       # 对象类型为Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
    - name: nginx     # Pod间通信的端口名称
      port: 80        # Pod间通信的端口号
  selector:
    app: nginx        # 选择标签为app:nginx的Pod
  clusterIP: None     # 必须设置为None，表示Headless Service

  [root@master ~]# kubectl apply -f headless.yaml
service/nginx created
[root@master ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        84d
nginx        ClusterIP   None            <none>        80/TCP         2s
svc1         ClusterIP   10.103.70.209   <none>        80/TCP         2d5h
svc666       NodePort    10.99.106.203   <none>        80:30827/TCP   27h
```

2.编辑yaml文件
```shell
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx
spec:
  serviceName: nginx                             # headless service的名称
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: container-0
          image: nginx:alpine
          resources:{}
          volumeMounts:                           # Pod挂载的存储
          - name:  data
            mountPath:  /usr/share/nginx/html     # 存储挂载到/usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: 1Gi
      storageClassName: nfs-client                 # 持久化存储的类型

[root@master ~]# kubectl apply -f sts.yaml
[root@master ~]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          29h
nginx-0                                   1/1     Running   0          28s
nginx-1                                   1/1     Running   0          17s
nginx-2                                   1/1     Running   0          6s
```
# daemonSet
daemonSet守护进程集。
它和之前的deployment/sts不一样，他们两个都是有副本机制replicas。但是daemonSet没有副本机制。集群中每个节点上有且只能有1个pod存在。
DaemonSet（守护进程集）在集群的每个节点上运行一个Pod，且保证只有一个Pod，非常适合一些系统层面的应用，例如日志收集、资源监控等，这类应用需要每个节点都运行，且不需要太多实例，一个比较好的例子就是Kubernetes的kube-proxy。

DaemonSet跟节点相关，如果节点异常，也不会在其他节点重新创建。

```shell
[root@master ~]# cat ds.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-daemonset
  labels:
    app: nginx-daemonset
spec:
  selector:
    matchLabels:
      app: nginx-daemonset
  template:
    metadata:
      labels:
        app: nginx-daemonset
    spec:
      nodeSelector:                 # 节点选择，当节点拥有daemon=need时才在节点上创建Pod
        daemon: need
      containers:
      - name: nginx-daemonset
        image: nginx:alpine
        resources: {}
```
注意：
1.为所有节点打上标签nginx-daemonset
2.为master取消污点（完成实验后，最好还原污点）

# job和cronjob
job：单次任务（普通任务）
cronjob：循环任务（定时任务）

job和CronJob是负责批量处理短暂的一次性任务（short lived one-off tasks），即仅执行一次的任务，它保证批处理任务的一个或多个Pod成功结束。

Job：是Kubernetes用来控制批处理型任务的资源对象。批处理业务与长期伺服业务（Deployment、StatefulSet）的主要区别是批处理业务的运行有头有尾，而长期伺服业务在用户不停止的情况下永远运行。Job管理的Pod根据用户的设置把任务成功完成就自动退出（Pod自动删除）。
CronJob：是基于时间的Job，就类似于Linux系统的crontab文件中的一行，在指定的时间周期运行指定的Job。
任务负载的这种用完即停止的特性特别适合一次性任务，比如持续集成。

apiVersion: batch/v1
kind: Job
metadata:
  name: pi-with-timeout
spec:
  completions: 10            # 运行的次数，即Job结束需要成功运行的Pod个数
  parallelism: 2             # 并行运行Pod的数量，默认为1
  backoffLimit: 5            # 表示失败Pod的重试最大次数，超过这个次数不会继续重试。
  activeDeadlineSeconds: 100  # 表示Pod超期时间，一旦达到这个时间，Job及其所有的Pod都会停止。
  template:                  # Pod定义
    spec: 
      containers:
      - name: pi
        image: perl
        command:
        - perl
        - "-Mbignum=bpi"
        - "-wle"
        - print bpi(2000)
      restartPolicy: Never

[root@master ~]# kubectl logs pi-with-timeout-5w5wk
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275901


cronjob

[root@master ~]# cat cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-example
spec:
  schedule: "*/1 * * * *"           # 定时相关配置
  jobTemplate:                             # Job的定义
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: pi
            image: perl
            command:
            - perl
            - "-Mbignum=bpi"
            - "-wle"
            - print bpi(2000)

[root@master ~]# kubectl get pod
NAME                                      READY   STATUS      RESTARTS   AGE
cronjob-example-28996643-prcmn            0/1     Completed   0          41s
nfs-client-provisioner-5c578b7757-lg659   1/1     Running     0          30h
pi-with-timeout-5w5wk                     0/1     Completed   0          10m
pi-with-timeout-74qtl                     0/1     Completed   0          10m
pi-with-timeout-d5zsv                     0/1     Completed   0          10m
pi-with-timeout-dzl29                     0/1     Completed   0          10m
pi-with-timeout-q9mml                     0/1     Completed   0          10m
pi-with-timeout-qbxwn                     0/1     Completed   0          10m
pi-with-timeout-qqmwx                     0/1     Completed   0          11m
pi-with-timeout-tjmgw                     0/1     Completed   0          11m
pi-with-timeout-tq9p5                     0/1     Completed   0          10m
pi-with-timeout-ws65c                     0/1     Completed   0          10m

不管是job还是cronjob，完成后的pod全部都在，无法自动清理。
如果要自动清理，可以添加一个参数 ttlSecondsAfterFinished: 60
表示pod完成后，状态变为completed后，等待多少秒被删除。

[root@master ~]# cat cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-example
spec:
  schedule: "*/1 * * * *"           # 定时相关配置
  jobTemplate:                             # Job的定义
    spec:
      ttlSecondsAfterFinished: 60
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: pi
            image: perl
            command:
            - perl
            - "-Mbignum=bpi"
            - "-wle"
            - print bpi(2000)

总结：
1.k8s中的控制器有哪些？deployment/statefulset/daemonset/job/cronjob
2.dep和sts有啥区别？无状态/有状态
