容器是应用程序每个组件的隔离进程。每个组件（前端 React 应用程序、Python API 引擎和数据库）都在自己的隔离环境中运行，与计算机上的其他所有内容完全隔离。

**容器的优点：**
- 自包含的（self-containered）。每个容器都有运行所需的一切，不依赖于主机上预安装的依赖项，包括网络。
- 由于容器是隔离运行的（进程级隔离），因此它们对主机和其他容器的影响最小，从而提高了应用程序的安全性。
- 每个容器都是独立管理的。删除一个容器不会影响其他容器。
- 跨平台。容器可以在任何地方运行，不依赖于宿主机的环境配置
- 启动极快。可达到亚秒级别。

**容器的缺点：**
- 可控制性不强，体现在应用运行，容器运行，应用如果关闭，则容器关闭。
- 和传统的物理服务器及虚拟机管理方式是不同的，传统物理服务器及虚拟机往往单独管理，容器可以批量管理。

**容器和虚拟机的区别：**





相关文档：
[What is a container? | Docker Docs](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)



