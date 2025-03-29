# RAID





一、什么是RAID

 redundant array of indepenfent disks  独立的磁盘冗余阵列

 

二、硬盘性能

1. SATA
2. SAS
3. SSD

SATA-SSD

SAS-SSD

nvme SSD

 

三、可靠性

RAID技术： 磁盘阵列：由两块或两块以上的硬盘，组成在一起，创建成一个虚拟磁盘

1. 提高性能
2. 提供冗余

 

硬件RAID： 购买RAID卡 RAID算法依赖于RAID算力来实现

软件RAID： OS 软件来实现 RAID算法依赖于CPU来计算

 

条带：RAID组中每个硬盘最小读写单元

分条：RAID组每个硬盘相同的位置组成在一起

 

奇偶校验算法（XOR）

镜像 RAID1

 

底层服务器做RAID，在RAID安装OS，并且做LVM

 

根据业务需求，创建不同级别的RAID

RAID0

数据条带化,无校验

RAID1

数据镜像,无校验

RAID3

带奇偶校验的阵列

校验盘会成为, 性能的瓶颈



RAID5

平均分布带奇偶校验的阵列

最多只能坏一块盘

SAS  RAID5 容量小 价格高,性能好

SATA RAID6 故障率高



RAID5: 适合于顺序大IO业务,备份业务,视频监控任务, 使用机械硬盘



RAID6



RAID10

RAID1 与 RAID0组合



RAID: 适合数据库业务, 读写随机, 小IO

MySQL  mongoDB 尽量使用SSD





RAID50

RAID5 与 RAID0组合



服务器中创建RAID

存储中创建RAID



服务器和存储均支持热插拔, 但是还是要看情况



热备盘: 顶替失效的盘

全局热备盘



问题: RAID 可以使用不同容量的硬盘创建RAID吗?
300G 600G RAID1: 300G

创建RAID成员盘建议同样大小同样性能, 同批次,备件



重构



RAID 1.0

RAID 2.0: 热备空间分散在各个RAID组中



RAID可以解决硬件故障, 例如一个磁盘坏了, 或者误操作删除, 病毒, 软件故障等

备份相当于独立存在的系统, 可以解决软件故障, 数据可以恢复

快照



RAID和LUN



远程管理卡

intel: IPMI协议

IPMI(只能平台管理接口), intelligent platform Managerment interface

开源





远程管理卡, 





RAID卡









# 实验

``` shell
lab.yutianedu.com:3000
liukaige
Huawei12#$







```

