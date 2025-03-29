## 关于pod的调度
cordon/drain/taint

```shell
[root@master ~]# kubectl taint node node1 aaa=bbb:NoSchedule
node/node1 tainted
[root@master ~]# kubectl describe nodes node1 |grep -i taint
Taints:             aaa=bbb:NoSchedule  老板画饼

[root@master ~]# kubectl taint node node2 aaa=ccc:NoSchedule
node/node2 tainted
[root@master ~]# kubectl describe nodes node2 |grep -i taint
Taints:             aaa=ccc:NoSchedule   老板pua
```

默认master本身也有污点，3台都有污点，直接创建pod，会pending
污点会配合着容忍度 toleration 一起使用（在 pod 上设置）

```shell
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"

tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

```shell
容忍 某个键==某个值
[root@master ~]# cat pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: nginx
    name: pod1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "aaa"
    operator: "Equal"
    value: "ccc"
    effect: "NoSchedule"
status: {}

容忍 某个键存在
[root@master ~]# cat pod2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod2
  name: pod2
spec:
  containers:
  - image: nginx
    name: pod2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "aaa"
    operator: "Exists"
    effect: "NoSchedule"
status: {}
```

也可以根据实际情况写多个容忍度，在NoSchedule情况下，只需满足任意一个即可调度
```shell
[root@master ~]# cat pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: nginx
    name: pod1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "aaa"
    operator: "Equal"
    value: "ccc"
    effect: "NoSchedule"
  - key: "kkk"
    operator: "Equal"
    value: "ggg"
    effect: "NoSchedule"
status: {}
```
# k8s 存储管理
本地存储：
emptyDir/hostPath
网络存储：
NFS，SAN等
持久性存储（重点）：
PV/PVC

网络存储NFS：
1.准备一台linux（50G）
2.分区格式化 10G
3.文件系统挂载
4.配置yum源安装软件包
```shell 
yum install -y yum-utils vim bash-completion net-tools wget nfs-utils
```

5.启动nfs服务
```shell
systemctl enable nfs-server.service
systemctl start nfs-server.service
```

6.关闭防火墙
```shell
systemctl disable firewalld.service
systemctl stop firewalld.service
setenforce 0
vim /etc/selinux/config

SELINUX=disabled
```

7.配置exports
```shell
[root@nfs ~]# vim /etc/exports
[root@nfs ~]# cat /etc/exports
/data *(rw,async,no_root_squash)
```

`exportfs -arv` //不用重启nfs服务，配置文件就会生效
`no_root_squash`：登入 NFS 主机使用分享目录的使用者，如果是 root 的话，那么对于这个分享的目录来说，他就具有 root 的权限！这个项目『极不安全』，不建议使用。以root身份写。
exportfs命令
-a 全部挂载或者全部卸载
-r 重新挂载
-u 卸载某一个目录
-v 显示共享目录

8.测试访问
k8s集群节点（node节点）安装nfs-utils
```shell
[root@node2 ~]# mkdir /test
[root@node2 ~]# mount 192.168.44.245:/data /test
[root@node2 ~]# df -Th
```

9.编辑yaml创建pod测试
注意：把之前的调度策略取消

```shell
[root@master ~]# kubectl run pod1 --image nginx --image-pull-policy IfNotPresent --dry-run=client -o yaml > pod1.yaml
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
  volumes:
  - name: v1
    emptyDir: {}
  - name: v2
    hostPath:
      path: /data
  - name: v3
    nfs:
      server: 192.168.44.245
      path: /data
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod1
    resources: {}
    volumeMounts:
    - name: v3
      mountPath: /usr/share/nginx/html/
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

```shell
[root@master ~]# kubectl exec -ti pod1 -- bash
root@pod1:/# cd /usr/share/nginx/html/
root@pod1:/usr/share/nginx/html# ls
root@pod1:/usr/share/nginx/html# touch {a,b,c}{1,2,3}.txt
root@pod1:/usr/share/nginx/html# ls
a1.txt  a2.txt  a3.txt  b1.txt  b2.txt  b3.txt  c1.txt  c2.txt  c3.txt
```

```shell
[root@nfs data]# ls
a1.txt  a2.txt  a3.txt  b1.txt  b2.txt  b3.txt  c1.txt  c2.txt  c3.txt
```

## k8s 持久化存储
PV、PVC不是一种新的存储类型，而是k8s用来做存储管理的一种资源对象。（先规划、再申请、最后使用）
- PV: persistent volume  持久卷
- PVC: persistent volume claim 持久卷申领
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250224153551417.png)

1.准备一个目录空间
用刚才的NFS，再创建一个5G分区。
```shell
[root@nfs ~]# cat /etc/exports
/data *(rw,async,no_root_squash)
/vol1 *(rw,async,no_root_squash)

[root@nfs ~]# exportfs -arv
exporting *:/vol1
exporting *:/data
```

2.创建PV
编辑yaml模板，可参考官方文档
https://kubernetes.io/docs/concepts/storage/persistent-volumes/
https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

```shell
[root@master ~]# vim pv01.yaml
[root@master ~]# cat pv01.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv01
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  nfs:
    path: "/vol1"
    server: 192.168.44.245
```

这里面有个`accessModes`访问模式
访问模式有：

`ReadWriteOnce`
卷可以被一个节点以读写方式挂载。 ReadWriteOnce 访问模式仍然可以在同一节点上运行的多个 Pod 访问（读取或写入）该卷。 对于单个 Pod 的访问，请参考 ReadWriteOncePod 访问模式。
`ReadOnlyMany`
卷可以被多个节点以只读方式挂载。
`ReadWriteMany`
卷可以被多个节点以读写方式挂载。
`ReadWriteOncePod`
特性状态： Kubernetes v1.29 [stable]
卷可以被单个 Pod 以读写方式挂载。 如果你想确保整个集群中只有一个 Pod 可以读取或写入该 PVC， 请使用 ReadWriteOncePod 访问模式。

在命令行接口（CLI）中，访问模式也使用以下缩写形式：

`RWO` - ReadWriteOnce
`ROX` - ReadOnlyMany
`RWX` - ReadWriteMany
`RWOP` - ReadWriteOncePod

```shell
[root@master ~]# kubectl apply -f pv01.yaml
persistentvolume/pv01 created
[root@master ~]# kubectl get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv01   5Gi        RWO            Retain           Available           manual         <unset>                          2s
```

RECLAIM POLICY 回收策略：常用两种 `retain`/`delete`
`Retain`（静态模式）：保留，当删除pod，删除pvc，删除pv的时候，底层数据依然保留。优点：可以防止误删除；缺点：需要定期清理无用的数据，占用大量存储空间。
`Delete`（动态模式）：删除，当删除pod，删除pvc，自动删除pv，自动删除底层数据。优点：及时清理了无效数据；缺点：如果误删除，数据丢失。

注意：一个pv是否可以被pvc进行申领，就是看`status`是否为 `Available`

3.创建pvc
```shell
[root@master ~]# vim pvc01.yaml
[root@master ~]# cat pvc01.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc01
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

[root@master ~]# kubectl apply -f pvc01.yaml
persistentvolumeclaim/mypvc01 created
[root@master ~]# kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
mypvc01   Bound    pv01     5Gi        RWO            manual         <unset>                 3s

[root@master ~]# kubectl get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv01   5Gi        RWO            Retain           Bound    default/mypvc01   manual         <unset>                          11m
```
假如创建了很多个pv，你创建一个pvc的时候，到底会**自动关联**哪个pv呢？
1. storageClassName: manual
2. accessModes:ReadWriteOnce
3. requests:storage: 5Gi
按照以上三个参数逐一匹配

静态卷，pvc 删除后，关联的 pv 状态变为 released，不可以被其他 pvc 关联，可以 `kubectl edit pv`, 删除 pv 的 uid 字段，但不推荐

## 动态卷制备
通过三方驱动可以实现，创建pvc的时候自动创建pv，删除pvc的时候，自动删除pv及底层数据（对应回收策略：delete）
底层如何关联，以及pv如何对接，这些全部都在yaml文件中定义好了。

1.配置NFS服务器
2.下载NFS外部插件（压缩包），解压

3.修改rbac.yaml并执行（设置权限）
```shell
[root@master deploy]# kubectl apply -f rbac.yaml
serviceaccount/nfs-client-provisioner created
clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner created
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
```
4.修改deployment.yaml并执行
```shell
[root@master deploy]# vim deployment.yaml
[root@master deploy]# cat deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.cn-hangzhou.aliyuncs.com/cloudcs/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: 192.168.44.245
            - name: NFS_PATH
              value: /vol1
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.44.245
            path: /vol1
```
5.创建存储类（默认delete）
```shell
[root@master deploy]# ls
class.yaml  deployment.yaml  kustomization.yaml  objects  rbac.yaml  test-claim.yaml  test-pod.yaml
[root@master deploy]# cat class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "false"

[root@master deploy]# kubectl get sc
No resources found
[root@master deploy]# kubectl apply -f class.yaml
storageclass.storage.k8s.io/nfs-client created
[root@master deploy]# kubectl get sc
NAME         PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client   k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate           false                  2s
```
6.创建pvc
```shell
[root@master deploy]# cat test-claim.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Mi

[root@master deploy]# kubectl apply -f test-claim.yaml
[root@master deploy]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-3b627704-c45f-45b7-a6b5-caacc148d600   500Mi      RWX            Delete           Bound    default/test-claim    nfs-client     <unset>     

[root@master deploy]# kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
test-claim    Bound    pvc-3b627704-c45f-45b7-a6b5-caacc148d600   500Mi      RWX            nfs-client     <unset>                 5m9s
```
底层查看
```shell 
[root@nfs vol1]# ls
default-test-claim-pvc-3b627704-c45f-45b7-a6b5-caacc148d600
```

7.创建pod测试
```shell
[root@master ~]# cat pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  volumes:
  - name: s1
    persistentVolumeClaim:
      claimName: test-claim
  containers:
  - image: nginx
    name: pod1
    resources: {}
    volumeMounts:
    - name: s1
      mountPath: /usr/share/nginx/html/
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

[root@master ~]# kubectl exec -ti pod1 -- bash
root@pod1:/# cd /usr/share/nginx/html/
root@pod1:/usr/share/nginx/html# ls
root@pod1:/usr/share/nginx/html# touch {a,b,c}{1,2,3}.txt
root@pod1:/usr/share/nginx/html# ls
a1.txt  a2.txt  a3.txt  b1.txt  b2.txt  b3.txt  c1.txt  c2.txt  c3.txt
```

查看nfs底层目录
```shell
[root@nfs vol1]# ls default-test-claim-pvc-3b627704-c45f-45b7-a6b5-caacc148d600/
a1.txt  a2.txt  a3.txt  b1.txt  b2.txt  b3.txt  c1.txt  c2.txt  c3.txt
```

8.删除测试
当删除pod，删除pvc之后，pv和底层数据会同时自动删除。
```shell
[root@master ~]# kubectl delete pvc test-claim2
[root@master ~]# kubectl get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
test-claim   Bound    pvc-3b627704-c45f-45b7-a6b5-caacc148d600   500Mi      RWX            nfs-client     <unset>                 8m5s
[root@master ~]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-3b627704-c45f-45b7-a6b5-caacc148d600   500Mi      RWX            Delete           Bound    default/test-claim   nfs-client     <unset>                          8m8s

[root@nfs vol1]# ll
total 0
drwxrwxrwx. 2 root root 132 Feb 16 14:39 default-test-claim-pvc-3b627704-c45f-45b7-a6b5-caacc148d600
```

# 控制器deployment
deployment
statefulset
daemonset
job
cronjob
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250224161418528.png)

## 了解deployment
默认情况下，手工创建的单个pod，不具备自愈能力，一旦被删除，不会自动恢复的。
deployment也是一种资源对象，和pod一样，通过ns进行隔离。
```shell
[root@master ~]# kubectl create deployment web1 --image nginx --dry-run=client -o yaml > web1.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: web1
  name: web1
spec:
  replicas: 3   副本数
  selector:  标签选择器
    matchLabels: 匹配标签
      app: web1  app=web1这个标签
  strategy: {}
  template:  模板
    metadata:
      creationTimestamp: null
      labels:
        app: web1
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

[root@master ~]# kubectl apply -f web1.yaml
[root@master ~]# kubectl get deployments.apps
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
nfs-client-provisioner   1/1     1            1           45m
web1                     3/3     3            3           11s

[root@master ~]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-5c578b7757-f95m8   1/1     Running   0          45m
pod1                                      1/1     Running   0          33m
web1-5fddd59776-65sb6                     1/1     Running   0          13s
web1-5fddd59776-nthrm                     1/1     Running   0          13s
web1-5fddd59776-tvcxz                     1/1     Running   0          13s
```

删除一个，就会创建一个，多出一个，就会删除一个，因为deployment务必保证集群中有足够的replicas副本数。

如果手工创建一个pod，并把pod的标签改为 app=web1,那么deployment会接管到这个pod吗？会的
```shell
[root@master ~]# kubectl get pod --show-labels
NAME                                      READY   STATUS    RESTARTS   AGE     LABELS
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          6m36s   app=nfs-client-provisioner,pod-template-hash=5c578b7757
pod1                                      1/1     Running   0          15s     run=pod1
web1-5fddd59776-6ddgv                     1/1     Running   0          61s     app=web1,pod-template-hash=5fddd59776
web1-5fddd59776-d25r2                     1/1     Running   0          61s     app=web1,pod-template-hash=5fddd59776
web1-5fddd59776-fxtv5                     1/1     Running   0          61s     app=web1,pod-template-hash=5fddd59776

[root@master ~]# kubectl label pods pod1 app=web1

[root@master ~]# kubectl get pod --show-labels
NAME                                      READY   STATUS    RESTARTS   AGE     LABELS
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          7m18s   app=nfs-client-provisioner,pod-template-hash=5c578b7757
pod1                                      1/1     Running   0          57s     app=web1,pod-template-hash=5fddd59776,run=pod1
web1-5fddd59776-6ddgv                     1/1     Running   0          103s    app=web1,pod-template-hash=5fddd59776
web1-5fddd59776-fxtv5                     1/1     Running   0          103s    app=web1,pod-template-hash=5fddd59776
```

当更改pod1的标签为 app=web1 时，会发现，deploy立刻删除了一个pod，始终保证集群内有3个副本。

## 修改副本数方法
1.在线改
```shell
[root@master ~]# kubectl edit deployments.apps web1
```

2.命令行修改
```shell
[root@master ~]# kubectl scale deployment web1 --replicas 6
```

3.修改yaml
```shell
spec:
  replicas: 20
[root@master ~]# kubectl apply -f web1.yaml
```

## HPA动态扩展
以上修改副本数，都是基于手工来修改的，如果面对未知的业务系统，业务并发量忽高忽低，总不能手工来来回回修改，那怎么办呢？
是否可以根据pod的负载，让它自动调节？使用HPA，类似于公有云的弹性负载AS。
比如规定每个pod的cpu阈值为80%，这时候就可以进行扩展。
HPA （Horizontal Pod Autoscaler） 水平自动伸缩，通过检测pod cpu的负载，解决deploy里某pod负载过高，动态伸缩pod的数量来实现负载均衡。
HPA一旦监测pod负载过高，就会通知deploy，要创建更多的副本数，这样每个pod负载就会轻一些。
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250224163101068.png)


1.添加resource的值
```shell
[root@master ~]# kubectl edit deployments.apps web1
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        resources:
          requests:
            cpu: 500m
```

2.创建HPA
```shell
[root@master ~]# kubectl autoscale deployment web1 --min 3 --max 10 --cpu-percent 10
horizontalpodautoscaler.autoscaling/web1 autoscaled
[root@master ~]# kubectl get hpa
NAME   REFERENCE         TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
web1   Deployment/web1   cpu: <unknown>/10%   3         10        0          3s
[root@master ~]# kubectl get hpa
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web1   Deployment/web1   cpu: 0%/10%   3         10        3          15s
```

3.外部压力测试
3.1 创建一个svc
```shell
[root@master ~]# kubectl expose deployment web1 --name svc666 --port 80 --target-port 80 --type NodePort
service/svc666 exposed
[root@master ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        83d
svc1         ClusterIP   10.103.70.209   <none>        80/TCP         25h
svc666       NodePort    10.99.106.203   <none>        80:30827/TCP   3s
```

3.2 安装压测工具ab
```shell
[root@nfs ~]# yum install -y httpd-tools.x86_64
[root@nfs ~]# ab -t 600 -n 1000000 -c 1000 http://192.168.44.202:30827/index.html
```

3.3 观察hpa target的百分比
```shell
[root@master ~]# kubectl get hpa
NAME   REFERENCE         TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
web1   Deployment/web1   cpu: 12%/10%   3         10        8          19m
```

因为我个人电脑cpu资源不够了，所以有一个被pending了。
之后，结束压测。等待一段时间，再次查看资源状态。会自动的删减pod。

```shell
[root@master ~]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          80m
web1-c4c56dd65-cksf2                      1/1     Running   0          9m22s
web1-c4c56dd65-k288c                      1/1     Running   0          27m
web1-c4c56dd65-v5smt                      1/1     Running   0          9m22s
```
## 镜像更新和回滚
```shell
[root@master ~]# kubectl exec -ti web1-c4c56dd65-cksf2 -- nginx -v
nginx version: nginx/1.27.4
```

1.在线改镜像版本
```shell
[root@master ~]# kubectl edit deployments.apps web1
    spec:
      containers:
      - image: nginx:1.25

[root@master ~]# kubectl get po
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-5c578b7757-lg659   1/1     Running   0          82m
web1-79c54c7567-c4qbk                     1/1     Running   0          19s
web1-79c54c7567-kmbbx                     1/1     Running   0          16s
web1-79c54c7567-zp5xs                     1/1     Running   0          32s
[root@master ~]# kubectl exec -ti web1-79c54c7567-c4qbk -- nginx -v
nginx version: nginx/1.25.5
```

2.更改yaml文件，之后apply
3.命令行
```shell
[root@master ~]# kubectl set image deployments web1 nginx=nginx:1.27.4
[root@master ~]# kubectl set image deployments web1 nginx=nginx:1.26.3
```

万一升级完成发现不兼容，直接选择回滚（默认只能回滚上一次最后一个版本）
```shell
[root@master ~]# kubectl rollout undo deployment web1

cd -
```

能否查看我之前更新的所有版本呢？默认查看都是空的，没有记录
```shell
[root@master ~]# kubectl rollout history deployment web1
deployment.apps/web1
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
5         <none>
6         <none>
7         <none>
8         <none>
11        <none>
12        <none>
```

如果想每次更新的时候产生记录，需要带上record

```shell
[root@master ~]# kubectl set image deployments web1 nginx=nginx:1.26.3 --record=true
[root@master ~]# kubectl set image deployments web1 nginx=nginx:1.27.4 --record=true
[root@master ~]# kubectl set image deployments web1 nginx=nginx:1.25.5 --record=true

[root@master ~]# kubectl rollout history deployment web1
deployment.apps/web1
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
5         <none>
6         <none>
7         <none>
8         <none>
13        kubectl set image deployments web1 nginx=nginx:1.26.3 --record=true
14        kubectl set image deployments web1 nginx=nginx:1.27.4 --record=true
15        kubectl set image deployments web1 nginx=nginx:1.25.5 --record=true

[root@master ~]# kubectl exec -ti web1-6bff9977d-rm8rn -- nginx -v
nginx version: nginx/1.25.5
```

未来想回退到指定的版本，也可以直接指定 revision 版本
```shell
[root@master ~]# kubectl rollout undo deployment web1 --to-revision 13
```

总结：更新镜像有3种方法
1.直接手工指定
```shell
kubectl set image deployments web1 nginx=nginx:1.27.4
```
2.直接回退
```shell
kubectl rollout undo deployment web1（cd -）
```
3.直接回退，手工来指定（开启了--record=true）
```shell
kubectl rollout undo deployment web1 --to-revision 13
```
