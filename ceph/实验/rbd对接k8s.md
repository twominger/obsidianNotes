# ceph 部分配置

1. 在 Ceph 集群中创建一个新的池 kubernetes
```shell
ceph osd pool create kubernetes
```
2. 启用 RBD 应用程序，以便在该池中存储 RADOS 块设备镜像
```shell
ceph osd pool application enable kubernetes rbd
```
3. 初始化该池，使其准备好存储 RBD 镜像
```shell
rbd pool init -p kubernetes
```
4. 在 rbd-data 池中创建一个名为 kubernetes-data，大小为 5GB 的 RBD 镜像
```shell
rbd create kubernetes-data --size 5G --pool kubernetes
```
5. 创建并导出 rbd 用户
```shell
ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes' -o /etc/ceph/ceph.client.kubernetes.keyring
```

# k8s 对接
> [! 注意]
> k8s 集群要求至少三个节点，且没有污点（控制节点污点 `node-role.kubernetes.io/control-plane:NoSchedule`），因为 `deployment.apps/csi-rbdplugin-provisioner ` 副本数为三，且
> ![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250321004600834.png)
> （表示反亲和性规则适用于节点级别，即 Pod 不会与符合标签选择条件的其他 Pod 调度到同一台主机（节点）上）

如果有污点：
```shell
# 查看污点
kubectl describe node master
# 清除污点
kubectl taint nodes master node-role.kubernetes.io/control-plane:NoSchedule-
```
## ceph-csi 插件下载
了解 [[ceph-csi]]

[ceph-csi的代码托管地址](https://github.com/ceph/ceph-csi)
[ceph-csi v3.13.0.tar.gz](https://github.com/ceph/ceph-csi/archive/refs/tags/v3.13.0.tar.gz)

解压并进入文件夹
```shell
[root@master kubernetes]# pwd
/root/Download/ceph-csi-3.13.0/deploy/rbd/kubernetes
[root@master kubernetes]# ls
csi-config-map.yaml      csi-nodeplugin-rbac.yaml        csi-rbdplugin.yaml   rbd.md
csidriver.yaml           csi-provisioner-rbac.yaml       csi-rbd-sc.yaml
csi-kms-config-map.yaml  csi-rbdplugin-provisioner.yaml  csi-rbd-secret.yaml
```

## ceph-csi 插件安装
### 1 . 生成配置文件 `csi-config-map.yaml`
csi-config-map.yaml为ceph-csi用于连接ceph monitor的配置文件
```shell
cat >csi-config-map.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "ceph-csi-config"
data:
  config.json: |-
    [
        {
            "clusterID": "7b7fc60e-fff8-11ef-94d3-000c29c2d345",
            "monitors": [
                "172.16.1.91:6789"
            ]
        }
    ]
EOF
```
其中 `clusterID` 和 `monitors` 可以通过命令 `ceph mon dump` 查看，如下：
```shell
[root@ceph1 ~]# ceph mon dump
epoch 1
fsid 7b7fc60e-fff8-11ef-94d3-000c29c2d345
last_changed 2025-03-13T10:48:45.514024+0000
created 2025-03-13T10:48:45.514024+0000
min_mon_release 16 (pacific)
election_strategy: 1
0: [v2:172.16.1.91:3300/0,v1:172.16.1.91:6789/0] mon.ceph1
dumped monmap epoch 1
```

生成后，将新的 ConfigMap 对象存储在 Kubernetes 中：
```shell
kubectl apply -f csi-config-map.yaml
```

### 2 . 为 CSI pod 部署 Ceph 配置的 ConfigMap
除了csi-config-map.yaml文件之外，ceph-csi还需要ceph.conf配置文件。
位于 `deploy/ceph-conf.yaml`。
```shell
kubectl create -f ../../ceph-conf.yaml
```

### 3 . 定义kms 的configmap
如果没有配置kms，则创建一个空的configmap即可
```shell
cat > csi-kms-config-map.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    {}
metadata:
  name: ceph-csi-encryption-kms-config
EOF
```
### 4 . 生成 ceph-csi cephx 密钥
将用于认证ceph的keyring配置为secret
```shell
cat >csi-rbd-secret.yaml <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
stringData:
  userID: kubernetes
  userKey: AQDJ4NtnRcjgDxAAGiK1ZsBJJIJbt/ufphubnA==
EOF
```
可在 ceph 集群中查看
```shell
[root@ceph1 ~]# ceph auth ls |grep client
[root@ceph1 ~]# ceph auth get client.kubernetes
[client.kubernetes]
        key = AQDJ4NtnRcjgDxAAGiK1ZsBJJIJbt/ufphubnA==
        caps mgr = "profile rbd pool=kubernetes"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=kubernetes"
exported keyring for client.kubernetes
```

生成后，将新的 Secret 对象存储在 Kubernetes 中：
```shell
kubectl apply -f csi-rbd-secret.yaml
```

### 5 . 配置 ceph-csi 插件
创建所需的 ServiceAccount 和RBAC ClusterRole/ClusterRoleBinding Kubernetes 对象。这些对象不一定需要自定义您的 Kubernetes 环境，因此可以从 ceph-csi 部署 YAML 中按原样使用：
```shell
kubectl apply -f csi-provisioner-rbac.yaml 
kubectl apply -f csi-nodeplugin-rbac.yaml
```
最后，创建 ceph-csi 置备程序和节点插件。使用 ceph-csi 容器发行版可能例外，这些对象不会不一定需要针对您的 Kubernetes 环境进行自定义，并且因此，可以从 ceph-csi 部署 YAML 中按原样使用：
```shell
kubectl apply -f csi-rbdplugin-provisioner.yaml
kubectl apply -f csi-rbdplugin.yaml
```

安装插件用到的镜像列表如下，需要自行下载相关镜像
```shell
quay.io/cephcsi/cephcsi:v3.10.1
registry.k8s.io/sig-storage/csi-attacher:v4.4.2
registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.9.1
registry.k8s.io/sig-storage/csi-provisioner:v3.6.2
registry.k8s.io/sig-storage/csi-resizer:v1.9.2
registry.k8s.io/sig-storage/csi-snapshotter:v6.3.2
```
6. 成功配置后 `kubectl get all` 结果如下:
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250321014235312.png)

# 使用 Ceph 块设备
## 创建 StorageClass
Kubernetes StorageClass 定义了一类存储。可以创建多个 StorageClass 对象以映射到不同的服务质量级别（即 NVMe 与基于 HDD 的池）和功能。

在创建storageclass之前，还需要创建一个csidriver：
```shell
kubectl apply -f csidriver.yaml
```

创建storageclass示例如下
```shell
cat >csi-rbd-sc.yaml <<EOF
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
   clusterID: 7b7fc60e-fff8-11ef-94d3-000c29c2d345
   pool: kubernetes
   imageFeatures: layering
   csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
   csi.storage.k8s.io/provisioner-secret-namespace: default
   csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: default
   csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
   csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard
EOF

kubectl apply -f csi-rbd-sc.yaml
```
> [! 注意]
> `clusterID`: 7b7fc60e-fff8-11ef-94d3-000c29c2d345
> ` pool`: kubernetes
> 这两个参数需要与 ceph 集群的 ID 和存储池名字对应

## 创建 PersistentVolumeClaim
PersistentVolumeClaim 是用户对抽象存储资源的请求。然后，PersistentVolumeClaim 将关联到 Pod 资源，以配置一个 PersistentVolume，该卷将由 Ceph 块镜像提供支持。可以包含可选的 volumeMode 以在挂载的文件系统之间进行选择 （默认）或基于原始块设备的卷。
### 创建基于块的 PVC 并使用
以下 YAML 可以是用于向 csi-rbd-sc StorageClass 请求原始块存储：
```shell
cat <<EOF > raw-block-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-rbd-sc
EOF

kubectl apply -f raw-block-pvc.yaml
```
将上述 PersistentVolumeClaim 作为原始块设备绑定到 Pod 资源的演示和示例如下：
```shell
cat <<EOF > raw-block-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-raw-block-volume
spec:
  containers:
    - name: fc-container
      image: fedora:26
      command: ["/bin/sh", "-c"]
      args: ["tail -f /dev/null"]
      volumeDevices:
        - name: data
          devicePath: /dev/xvda
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: raw-block-pvc
EOF

kubectl apply -f raw-block-pod.yaml
```
### 创建基于文件系统的 PVC 并使用
可以使用以下 YAML 来从 csi-rbd-sc StorageClass 请求挂载的文件系统（由 RBD 镜像支持）:
```shell
cat <<EOF > pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rbd-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-rbd-sc
EOF

kubectl apply -f pvc.yaml
```
将上述 PersistentVolumeClaim 作为挂载的文件系统绑定到 Pod 资源的演示和示例如下：
```shell
cat <<EOF > pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: csi-rbd-demo-pod
spec:
  containers:
    - name: web-server
      image: nginx
      volumeMounts:
        - name: mypvc
          mountPath: /var/lib/www/html
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: rbd-pvc
        readOnly: false
EOF

kubectl apply -f pod.yaml
```

#参考资料 ：
[块设备和 Kubernetes — Ceph 文档](https://docs.ceph.com/en/pacific/rbd/rbd-kubernetes/)
[课堂笔记](https://www.wolai.com/oXsfBPpSVHUqinUzkdW2SE)
[kubernetes 卷](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/)
