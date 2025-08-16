Docker Engine 是一种开源容器化技术，用于构建和容器化您的应用程序。Docker Engine 作为一个客户端-服务器应用程序运行，由以下三部分组成：

- 长期运行的守护进程 dockerd。
- 指定程序可用于与 Dockerd 通信并对其进行操作的接口的应用程序编程接口(API)。
- 命令行界面（CLI）客户端。

CLI 使用 Docker API 通过脚本或直接使用 CLI 命令来控制 Dockerd 或与之交互。许多其他 Docker 应用程序使用底层 API 和 CLI。守护程序创建和管理 Docker 对象，例如镜像、容器、网络和卷。

