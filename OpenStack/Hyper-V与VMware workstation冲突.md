使用 DevEco Studio 中的 HarmonyOS 仿真器需要开启 Hyper-V、Virtual Machine Platform、Windows 虚拟机监控程序平台（在控制面板\所有控制面板项\程序和功能\启用或关闭 Windows 功能中打开，Hyper-V 选项可能没有，需要先打开另外两个，重启之后就会显示，再打开 Hyper-V）

>  也有可能 windows 家庭版没有 Hyper-V 功能，需要执行脚本安装（百度：windows 家庭版安装 hyper-v）

打开 Hyper-V 之后并重启之后，VMware 中所有之前创建的虚拟机都无法正常打开，提示"您正在运行的此虚拟机已启用侧通道缓解。侧通道缓解可增强安全性，但也会降低性能"，如果之前为挂起状态则无法启动，或者放弃挂起状态之后可以启动，但是以后每次开机都会有这个提示有点烦，且提示会降低性能
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250325180515440.png)
按照提示在虚拟机关机之后进入虚拟机设置/选项/高级中勾选禁用测通道缓存，然后再开启虚拟机可以正常开机，不会有提示，但是进入虚拟机后网络失效可以通过以下命令恢复网络：
```shell
nmcli	networking on
```

>  还需要检查 windows 安全中心，在设备安全性中关闭内核隔离

之后虚拟机可以正常使用

在部署 openstack 平台时，计算节点需要开启 CPU 虚拟化，但是开启后依然提示"此平台不支持虚拟化的 IntelVT-x/EPT"
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250325175503410.png)
点击“是”后提示“VMwareWorkstation 在此主机上不支持嵌套虚拟化”
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250325175736176.png)

原因是：不能同时开启hyper-V和VMware虚拟机软件，两者只能选择其一来使用，要用VMware虚拟机就必须关闭hyper-V

在"控制面板\所有控制面板项\程序和功能\启用或关闭 Windows 功能" 中取消勾选Hyper-V、Virtual Machine Platform、Windows 虚拟机监控程序平台，然后重启，依然无法解决，提示相同

解决方法：
管理员身份启动“cmd”，运行
```shell
bcdedit /set hypervisorlaunchtype off
```
重启，发现没有提示，所有虚拟机完全正常，并且虚拟机设置/选项/高级中有关侧通道缓解的选项也消失，openstack 可以正常部署

但是，DevEco Studio 中的仿真器无法正常打开
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250325180431018.png)

无解


参考资料：
[【经验】VMware｜Win11的Ubuntu虚拟机启动虚拟化，报错此平台不支持虚拟化的 Intel VT-x/EPT（方案汇总+自己的解决方案）_此平台不支持虚拟化的 intel vt-x ept-CSDN博客](https://blog.csdn.net/qq_46106285/article/details/127745752?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-0-127745752-blog-134643080.235^v43^pc_blog_bottom_relevance_base2&spm=1001.2101.3001.4242.1&utm_relevant_index=3)

[VMware Workstation 在此主机上不支持嵌套虚拟化。 模块“HV”启动失败。 未能启启动虚拟机-CSDN博客](https://blog.csdn.net/m0_62571257/article/details/124102636)

[为启用了Hyper-V的主机禁用侧通道缓解](https://blog.csdn.net/m0_62571257/article/details/124102636https://blog.csdn.net/m0_62571257/article/details/124102636)




