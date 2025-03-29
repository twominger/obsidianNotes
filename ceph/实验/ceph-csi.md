ceph-csi扩展各种存储类型的卷的管理能力，实现第三方存储ceph的各种操作能力与k8s存储系统的结合。调用第三方存储ceph的接口或命令，从而提供ceph数据卷的创建/删除、挂载/解除挂载的具体操作实现。前面分析组件中的对于数据卷的创建/删除、挂载/解除挂载操作，全是调用ceph-csi，然后由ceph-csi调用ceph提供的命令或接口来完成最终的操作。

[[csi]浅聊ceph-csi组件 - 一介布衣·GZ - 博客园](https://www.cnblogs.com/acommoners/p/15988974.html)