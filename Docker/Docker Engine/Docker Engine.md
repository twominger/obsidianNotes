Docker Engine 是一种开源容器化技术，用于构建和容器化您的应用程序。Docker Engine 作为一个客户端-服务器应用程序运行，由以下三部分组成：

- 长期运行的守护进程 dockerd。
- 指定程序可用于与 Dockerd 通信并对其进行操作的接口的应用程序编程接口(API)。
- 命令行界面（CLI）客户端。

CLI 使用 Docker API 通过脚本或直接使用 CLI 命令来控制 Dockerd 或与之交互。许多其他 Docker 应用程序使用底层 API 和 CLI。守护程序创建和管理 Docker 对象，例如镜像、容器、网络和卷。

Docker 使用客户端-服务器架构。Docker 客户端与 Docker 守护进程通信，后者负责构建、运行和分发 Docker 容器的繁重工作。Docker 客户端和守护程序可以在同一系统上运行，也可以将 Docker 客户端连接到远程 Docker 守护程序。Docker 客户端和守护进程使用 REST API、UNIX 套接字或网络接口进行通信。另一个 Docker 客户端是 Docker Compose，它允许您使用由一组容器组成的应用程序。

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250816161625689.png)

## The Docker daemon
Docker 守护程序 （`dockerd`） 侦听 Docker API 请求并管理 Docker 对象，例如映像、容器、网络和卷。守护进程还可以与其他守护进程通信来管理 Docker 服务。

## The Docker client
Docker 客户端 （`docker`） 是许多 Docker 用户与 Docker 交互的主要方式。当您使用 `docker run` 等命令时，客户端会将这些命令发送到 `dockerd，由 dockerd` 执行它们。`docker` 命令使用 Docker API。Docker 客户端可以与多个守护进程通信。


