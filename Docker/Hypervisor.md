# Hypervisor

## 1.概念

Hypervisor——一种运行在基础物理服务器和操作系统之间的中间软件层,可允许多个操作系统和应用共享硬件。也可叫做VMM（ virtual machine monitor ），即虚拟机监视器。

Hypervisors是一种在虚拟环境中的“元”操作系统。他们可以访问服务器上包括磁盘和内存在内的所有物理设备。Hypervisors不但协调着这些硬件资源的访问，而且在各个虚拟机之间施加防护。当服务器启动并执行Hypervisor时，它会加载所有虚拟机客户端的操作系统同时会分配给每一台虚拟机适量的内存，CPU，网络和磁盘。

## 2.作用

Hypervisor是所有虚拟化技术的核心。 非中断地支持多工作负载迁移的能力是Hypervisor的基本功能。

## 3.种类

目前市场上各种x86 管理程序(hypervisor)的架构存在差异，三个最主要的架构类别包括：

I型：虚拟机直接运行在系统硬件上，创建硬件全仿真实例，被称为“裸机”型。 裸机型在虚拟化中Hypervisor直接管理调用硬件资源，不需要底层操作系统，也可以将Hypervisor看作一个很薄的操作系统。这种方案的性能处于主机虚拟化与操作系统虚拟化之间。

II型：虚拟机运行在传统操作系统上，同样创建的是硬件全仿真实例，被称为“托管（宿主）”型。托管型/主机型Hypervisor运行在基础操作系统上，构建出一整套虚拟硬件平台（CPU/Memory/Storage/Adapter），使用者根据需要安装新的操作系统和应用软件，底层和上层的操作系统可以完全无关化，如Windows运行Linux操作系统。主机虚拟化中VM的应用程序调用硬件资源时需要经过:VM内核->Hypervisor->主机内核，因此相对来说，性能是三种虚拟化技术中最差的。

Ⅲ型：虚拟机运行在传统操作系统上，创建一个独立的虚拟化实例（容器），指向底层托管操作系统，被称为“操作系统虚拟化”。操作系统虚拟化是在操作系统中模拟出运行应用程序的容器，所有虚拟机共享内核空间，性能最好，耗费资源最少。但是缺点是底层和上层必须使用同一种操作系统，如底层操作系统运行的是Windows系统，则VPS/VE就必须运行Windows。

厂商 目前市场主要厂商及产品：VMware vSphere、微软Hyper-V、Citrix XenServer 、IBM PowerVM、Red Hat Enterprise Virtulization、Huawei FusionSphere、开源的KVM、Xen、VirtualBSD等。

## 4.特点

软硬件架构和管理更高效、更灵活，硬件的效能能够更好地发挥出来。

## 5.多Hypervisor

服务器虚拟化需要评估、选择和部署hypervisor，组织通常会选择一种主流的hypervisor：VMware的ESXi、微软的Hyper-V或者思杰的XenServer。然而，对很多组织来说，单独的hypervisor已经不能满足所有的虚拟化需求。这时候可以选择采用第二类hypervisor产品。随着服务器虚拟化技术的成熟，多hypervisor环境已经变得常见。但是，采用第二类虚拟化平台时，必须要仔细考虑其成本、部署范围和总开销。