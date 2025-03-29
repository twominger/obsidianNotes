# SVC 服务发布
svc的clusterip只是集群内部可见的，我们创建集群的目的，是为了给外界主机访问的。
可这个ip无法从外部直接访问的，这时候，可以把该服务发布出去，让外界主机可以访问到。
要发布，有几种方式：
1.ClusterIP(含无头headless服务)
2.NodePort
3.LoadBalancer
4.ExternalName

5.Ingress（单独）

1.ClusterIP
默认创建的SVC，采用的默认类型clusterip，clusterip是一个虚拟ip（不是真实存在的），提供给集群内部组件或者内部pod访问，不能对外访问。

k8s里面几大IP地址分类：
1）节点IP 192.168.44.0/24
2）Pod IP 10.244.0.0/16
3）SVC IP 没有设置，默认 10.96.0.0/12

另：clusterip如果没有IP地址，无头服务headless service

2.NodePort
[root@master ~]# kubectl expose deployment web1 --name nodeportsvc --port 80 --target-port 80
[root@master ~]# kubectl expose deployment web1 --name nodeportsvc2 --port 80 --target-port 80 --type NodePort
[root@master ~]# kubectl get svc
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP        87d
nginx          ClusterIP   None             <none>        80/TCP         2d23h
nodeportsvc    ClusterIP   10.101.157.139   <none>        80/TCP         19s
nodeportsvc2   NodePort    10.103.243.150   <none>        80:31781/TCP   4s

3.LoadBalancer

这种类型是要配合着公有云厂商（ELB负载均衡器）使用的。公有云厂商有公网IP地址池。

metallb 构建的公网地址池，其实本质上还是私网（L2 和节点网段保持一致）。

配合云厂商ELB的公网使用。
但我们实验环境中，如果要模拟可以采用metallb（controller/speaker）
controller：为负载均衡器分配一个公网ip
speaker：daemonset方式运行在每一个节点上，向外通告公网ip

1.执行yaml
[root@master ~]# kubectl apply -f metallb-native.yaml

[root@master ~]# kubens metallb-system
Context "kubernetes-admin@kubernetes" modified.
Active namespace is "metallb-system".
[root@master ~]# kubectl get daemonsets.apps
NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
speaker   3         3         1       3            1           kubernetes.io/os=linux   23s
[root@master ~]#
[root@master ~]# kubectl get svc
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
metallb-webhook-service   ClusterIP   10.99.217.177   <none>        443/TCP   32s
[root@master ~]#
[root@master ~]# kubectl get pod
NAME                          READY   STATUS    RESTARTS   AGE
controller-6678c7d67b-5mpkk   1/1     Running   0          39s
speaker-bknnl                 1/1     Running   0          39s
speaker-bpxdz                 1/1     Running   0          39s
speaker-sdqvb                 1/1     Running   0          39s
[root@master ~]# kubectl get deployments.apps
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
controller   1/1     1            1           62s

2.创建地址池
https://metallb.universe.tf/configuration/

当前master节点ip地址为：192.168.146.139

安装小工具查看网络段，计算ip子网
[root@kmaster svc]# yum install -y epel-release
[root@kmaster svc]# yum install -y sipcalc
[root@kmaster svc]# sipcalc 192.168.146.139/24
-[ipv4 : 192.168.146.139/24] - 0

[CIDR]
Host address		- 192.168.146.139
Host address (decimal)	- 3232273035
Host address (hex)	- C0A8928B
Network address		- 192.168.146.0
Network mask		- 255.255.255.0
Network mask (bits)	- 24
Network mask (hex)	- FFFFFF00
Broadcast address	- 192.168.146.255
Cisco wildcard		- 0.0.0.255
Addresses in network	- 256
Network range		- 192.168.146.0 - 192.168.146.255
Usable range		- 192.168.146.1 - 192.168.146.254


[root@master ~]# vim ippool.yaml
[root@master ~]# cat ippool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.44.230-192.168.44.240

[root@master ~]# kubectl apply -f ippool.yaml

3.创建实例并绑定地址池
[root@master ~]# vim l2pool.yaml
[root@master ~]# cat l2pool.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

[root@master ~]# kubectl apply -f l2pool.yaml

[root@master ~]# kubectl get ipaddresspools.metallb.io
NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["192.168.44.230-192.168.44.240"]

[root@master ~]# kubectl expose deployment web1 --name svclb --port 80 --target-port 80 --type LoadBalancer
service/svclb exposed

[root@master ~]# kubectl get svc svclb
NAME    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
svclb   LoadBalancer   10.99.87.104   192.168.44.230   80:31450/TCP   10s

直接通过公网IP地址访问192.168.44.230

4.ExternalName（几乎不用）

先了解下基于Endpoint类型的外部服务。
svc中会有关联Endpoint（通过标签进行关联，但是它是如何找到ip的？通过单独的一个资源对象将对应的这一组pod的ip给保存起来了。这个对象就是endpoint，也就是创建一个svc，就会对应创建一个同名EP endpoint，就像创建deployment一样，创建一个dep，就会创建一个rs，来管理pod副本）
接下来思考一个问题：
如果k8s集群内的pod需要访问外部服务，比如一个web集群，理论上说只要网络通的情况下，就可以访问，但如果web集群是一个高可用集群，如何实现负载均衡？
可以依赖于k8s集群内部的service（称之为叫ExternalService），也就是单独定义一个Endpoint，里面的地址指定外部的web集群IP地址，之后将EP和SVC绑定即可。类似于：

apiVersion: v1
kind: Endpoints
metadata:
  labels:
    app: web1
  name: mysql
  namespace: default
subsets:
- addresses:
  - ip: 10.244.104.31  要访问外部的一个地址
  ports:
    - port: 3306
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: web1
  name: mysql
  namespace: default
spec:
  ports:
    - port: 3306

当执行这个yaml文件的时候，SVC和这个EP就可以绑定到一起。

但如果这个外部的集群服务没有提供ip地址，默认提供的是域名。这时候endpoint是无法使用域名的。
直接使用外部域名不就行了？
确实可以直接通过域名访问外部服务，例如在集群内部的应用中直接使用 curl external-db.example.com。
但是，这有一些缺点：
- 不利于维护：如果外部域名发生变化，你的每个应用都需要更新配置。
- 缺乏统一性：每个服务都需要独立处理与外部服务的连接配置，导致管理上分散，不够集中。
- 无法通过 Kubernetes 原生服务发现机制来管理外部服务：
使用 ExternalName 后，外部服务的访问就和 Kubernetes 的服务发现机制集成，符合 K8s 的统一管理理念。

ExternalName 类型的 Service 提供了一个简单的 DNS 代理，使得你能够在 Kubernetes 集群内部，通过集中的方式（服务名）访问外部服务，而不需要在每个应用中硬编码外部域名。它帮助你将外部服务的访问抽象化，简化了服务配置和维护，特别适合在多个应用需要访问同一外部服务时使用。
如果你的场景中对外部服务的域名已经非常清晰且不会频繁变化，并且不需要集中管理外部依赖，那么你可能不需要 ExternalName，直接使用外部域名也完全可以。如果你有多个外部依赖需要管理，ExternalName 会让这部分的服务发现和配置管理变得更简洁。

apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: external-db.example.com

这样，就可以实现k8s集群内部的所有应用，在访问外部db的时候，只需要访问 external-db 即可。
即便后期外部域名发生了变化，也只需要维护SVC即可，无需手工维护一个又一个应用。

5.ingress
通过域名（做7层负载均衡）来实现访问后端不同pod（看到不同内容）

面试的时候有个很大的坑。ingress-controller它根据路由规则，通过svc获取ep地址，直接将流量传递给后端的对应pod，流量不再经过SVC。

https://support.huaweicloud.com/basics-cce/kubernetes_0025.html

1）创建3个pod
[root@master ~]# kubectl run pod1 --image nginx
pod/pod1 created
[root@master ~]# kubectl run pod2 --image nginx
pod/pod2 created
[root@master ~]# kubectl run pod3 --image nginx

2）为3个pod创建svc（默认clusterip）
[root@master ~]# kubectl expose pod pod1 --name n1svc --port 80 --target-port 80
[root@master ~]# kubectl expose pod pod2 --name n2svc --port 80 --target-port 80
[root@master ~]# kubectl expose pod pod3 --name n3svc --port 80 --target-port 80

3）修改3个pod内容
[root@master ~]# kubectl exec -ti pod1 -- bash
root@pod1:/# echo 111 > /usr/share/nginx/html/index.html
root@pod1:/# exit
exit
[root@master ~]# kubectl exec -ti pod2 -- bash
root@pod2:/# echo 222 > /usr/share/nginx/html/index.html
root@pod2:/# exit
exit
[root@master ~]# kubectl exec -ti pod3 -- bash
root@pod3:/# echo 333 > /usr/share/nginx/html/index.html
root@pod3:/# exit
exit

4）启用默认类让路由规则生效
[root@master ~]# kubectl get ingressclasses.networking.k8s.io
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       16m

[root@kmaster ~]# kubectl edit ingressclasses.networking.k8s.io nginx 
ingressclass.networking.k8s.io/nginx edited

添加ingressclass一行
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"  添加这一行
    kubectl.kubernetes.io/last-applied-configuration: |


5) 配置路由规则
注意：因为规则里面有涉及到后端的svc，所以要在后端svc所在的ns中创建。

[root@master ~]# vim ingress.yaml
[root@master ~]# cat ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wildcard-host
spec:
  rules:
  - host: "www.aaa.com"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: n1svc
            port:
              number: 80
  - host: "www.bbb.com"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: n2svc
            port:
              number: 80
  - host: "www.ccc.com"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: n3svc
            port:
              number: 80

路由规则配置完成后，默认不生效
[root@master ~]# kubectl apply -f ingress.yaml
ingress.networking.k8s.io/ingress-wildcard-host created
[root@master ~]# kubectl get ingress
NAME                    CLASS    HOSTS                                 ADDRESS   PORTS   AGE
ingress-wildcard-host   <none>   www.aaa.com,www.bbb.com,www.ccc.com             80      5s

[root@master ~]# kubectl describe ingress ingress-wildcard-host
Name:             ingress-wildcard-host
Labels:           <none>
Namespace:        default
Address:
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host         Path  Backends
  ----         ----  --------
  www.aaa.com
               /   n1svc:80 (10.244.166.178:80)
  www.bbb.com
               /   n2svc:80 (10.244.166.183:80)
  www.ccc.com
               /   n3svc:80 (10.244.166.155:80)
Annotations:   <none>
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    4s    nginx-ingress-controller  Scheduled for sync

6） 测试
找一台linux或者windows
修改 /etc/hosts
修改 C:\Windows\System32\drivers\etc\hosts

192.168.44.231 www.aaa.com
192.168.44.231 www.bbb.com
192.168.44.231 www.ccc.com

最后，在浏览器中分别访问 aaa.com /bbb.com/ccc.com 观察



