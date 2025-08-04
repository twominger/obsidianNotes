---
title: "我来 wolai - 不仅仅是未来的云端协作平台与个人笔记"
source: "https://www.wolai.com/breezey/qkDkL7djxCCrocbuZqFoHc"
author:
  - "[[我来 wolai - 不仅仅是未来的云端协作平台与个人笔记]]"
published:
created: 2025-08-04
description: "用 “我来” 搭建一站式协作平台，团队知识库、仪表台、工作流、内部应用、外部网站与个人云端笔记、待办……开箱即用！"
tags:
  - "clippings"
---
SRE WebService Java 应用 JVM 详解

演示模式 搜索 前往我的空间

java 简介

Java 语言是一门通用的、面向对象的、支持并发的程序语言。其诞生于 1995 年，主要发展历程如下：

![](https://secure2.wostatic.cn/static/8hNjtvwZkPdCjNw4MoSRfg/image.png?auth_key=1754317631-2nR8bRg6Nf4iMuLF2pZDf5-0-65e78980dd7f4e004660cf76e0e33ef6&image_process=resize,w_1440&file_size=126843)

jvm 简介

Java 语言之所以能广受欢迎，其中的原因之一是 Java 是一门可以跨平台的语言。而跨平台的特性就是通过 Java 虚拟机（JVM）是实现的。JVM 是整个 Java 平台的基石。其可以看作是一个抽象的计算机。编译器将 Java 文件编译为 Java 字节码文件（.class），接下来 JVM 对字节码文件进行解释，翻译成特定底层平台匹配的机器指令并运行：

![](https://secure2.wostatic.cn/static/3RJKpBSMZ7chcbDqz5j8kP/image.png?auth_key=1754317631-8u9jwacVHkXHmaQw35HHq-0-27ce6395c34d484291479624a0d744be&image_process=resize,w_936&file_size=28482)

JVM 和 Java 语言没有必然的联系，它只与 class 文件格式关联。也就是任何语言，只要能编译成符合规范的字节码文件，都是能被 Jvm 运行的。也就是说 JVM 是跨语言的平台 。

![](https://secure2.wostatic.cn/static/36r8bJa1ZMEuFwL4MDqfee/image.png?auth_key=1754317631-i2jLTacy9P2sRPWjCqZxZd-0-2903207f0fc16aca6ac027b3b7fd90a6&image_process=resize,w_720&file_size=14449)

java 虚拟机的实现

Java 虚拟机是一种规范，它指定了 Java 虚拟机结构、class 文件格式、类加载过程等。我们平时所提到的 Java 虚拟机一般指的是一种具体的 Java 虚拟机的实现，例如最知名的 hotspot，遵循 Java 虚拟机规范，甚至可以自己实现 Java 虚拟机。

1\. HotSpot VM

HotSpot 虚拟机是现在应用最广泛的虚拟机，它是 Sun/OracleJDK 和 OpenJDK 中的默认 Java 虚拟机。

但是这款虚拟机在最初并非由 Sun 公司所开发，而是由一家名为“Longview Technologies”的小公司设计；甚至这个虚拟机最初并非是为 Java 语言而研发的，它来源于 Strongtalk 虚拟机。

Oracle 收购 Sun 以后，建立了 HotRockit 项目来把原来 BEA JRockit 中的优秀特性融合到 HotSpot 之中。到了 2014 年的 JDK 8 时期，里面的 HotSpot 就已是两者融合的结果，HotSpot 在这个过程 里移除掉永久代，吸收了 JRockit 的 Java Mission Control 监控工具等功能。 得益于 Sun/OracleJDK 在 Java 应用中的统治地位，HotSpot 理所当然地成为全世界使用最广泛的 Java 虚拟机，是虚拟机家族中毫无争议的“武林盟主”。

2\. BEA JRockit/IBM J9 VM

除了 Sun/Oracle 公司以外，也有其他组织、公司开发过虚拟机的实现。除了 HotSpot 之外，BEA JRockit 和 IBM J9 VM 曾经与 HotSpot 并称“三大商业 Java 虚拟机”，它们分别由 BEA System 公司和 IBM 公司开发。

除此之外，还有一些公司也号称有自己的专属 JDK 和虚拟机，但是它们要么是通过从 Sun/Oracle 公司购买版权的方式获得的（如 HP、SAP 等），要么是基于 OpenJDK 项目改进而来的 （如阿里巴巴、Twitter 等），都并非自己独立开发。

JDK&JRE&JVM

![](https://secure2.wostatic.cn/static/dzeCqrdzrUridQt5i7jZbB/image.png?auth_key=1754317631-tvwJeQJEsun8wwdzBpDmwA-0-3d48ebaa089de7aa6bc82213d5b5c894&image_process=resize,w_1728&file_size=555232)

JDK&JRE&JVM 三者常常被用来比较：

JDK：Java 开发工具包，其全称为 java development Kit。JDK 是提供给 Java 开发人员使用的，其中包含了 Java 的开发工具，也包括了 JRE。其中的开发工具包括编译工具如 javac 、打包工具如 jar 等；

JRE：Java 运行环境，其全称为 Java Runtime Environment 。JRE 是 JDK 的子集，JRE 提供了运行 java 应用程序所必备的库文件、Java 虚拟机（JVM）和其他组件，其主要用于运行 Java 应用程序；

JVM：Java 虚拟机，其全称为 Java Virtual Machine 。JVM 可以理解为是一个虚拟出来的计算机，具备着计算机的基本运算方式，它主要负责把 Java 程序生成的字节码文件。

三者关系图如下：

![](https://secure2.wostatic.cn/static/oPUSdhTs5Dk2rVW6xqTvbr/image.png?auth_key=1754317631-bM4nZ5qe4tdhSuBnXYEKjV-0-a5b9f3201244911952ce93a9273ebff2&image_process=resize,w_1080&file_size=29001)

安装 JDK

jdk 自 1.8.0\_202 之后，不再免费，转而使用 openjdk。如果需要自行构建 openjdk8 的镜像，可在此下载相关的二进制包：

[GitHub - AdoptOpenJDK/semeru8-binaries](https://github.com/AdoptOpenJDK/semeru8-binaries/)

如果要找更老的 jdk 二进制包，可以在这里找到：

[GitHub - AdoptOpenJDK/openjdk8-upstream-binaries: Archived release scripts/releases of OpenJDK 8u project builds. Superseded by Eclipse Temurin releases.](https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries)

openjdk11：

[GitHub - AdoptOpenJDK/semeru11-binaries](https://github.com/AdoptOpenJDK/semeru11-binaries)

openjdk17:

[GitHub - AdoptOpenJDK/semeru17-binaries](https://github.com/AdoptOpenJDK/semeru17-binaries)

这里以安装 jdk 1.8 作为示例：

附录

参考： [【JVM 进阶之路】一：Java 虚拟机概览-腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1803273)

标题目录

java 简介

jvm 简介

java 虚拟机的实现

1\. HotSpot VM

2\. BEA JRockit/IBM J9 VM

JDK&JRE&JVM

安装 JDK

附录