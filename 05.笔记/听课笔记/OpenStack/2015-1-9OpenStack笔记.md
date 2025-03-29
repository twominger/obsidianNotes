# neutron

namespace: 命名空间


[Linux Namespace : 简介 - sparkdev - 博客园](https://www.cnblogs.com/sparkdev/p/9365405.html)
[【Linux】资源隔离机制 — 命名空间（Namespace）详解_linux namespace-CSDN博客](https://blog.csdn.net/Dreaming_TI/article/details/144539894)

**UTS**：每个容器可以拥有独立的主机名和域名，容器内的进程只看到自己的 hostname，互不干扰。
**IPC**：同一个 IPC 命名空间内的进程可以相互通信，而不同的 IPC 命名空间中的进程则无法通信。
**PID**：每个 PID 命名空间内的进程有独立的进程编号，因此每个容器可以有一个 PID 为 1 的 root 进程。
**Network**：每个容器拥有独立的网络环境，包括网络设备、IP 地址、路由表、端口号等。容器内的网络与主机或其他容器的网络互相隔离。
**Mount**：每个容器拥有独立的文件系统层次结构，容器内的进程只能看到自己的文件系统挂载点。
**User**：每个容器内的进程可以拥有独立的用户和组 ID，与主机或其他容器的用户和组 ID 隔离。

[ovs原理与实践](https://mp.weixin.qq.com/s/KVtja9QUTbnyx77tSzTW3g)
[ovn原理与实践](https://mp.weixin.qq.com/s?__biz=MzAwMDQyOTcwOA==&mid=2247485357&idx=1&sn=1e80c02232e2bdafec8dcf71dd4fa265&chksm=9ae85c4ead9fd5584e488f7f7f5b7d2ad4bd86c18cb780d057653b23eac4001dabe8f9b6d98a&cur_album_id=2470011981178322946&scene=189#wechat_redirect)






