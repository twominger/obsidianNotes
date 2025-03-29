先按照正常步骤[[ceph/实验/使用cephadm部署ceph集群|使用cephadm部署ceph集群]]，不添加 osd
创建文件分区
```shell
yum -y install gdisk
for i in 1 2 3 4 5 6 7 8 9 ; do sgdisk -n $i:0:+10G /dev/sdb ; done
```
使用分区创建逻辑卷，并添加 osd
```shell
pvcreate /dev/sdb1
vgcreate ceph_vg1 /dev/sdb1
lvcreate -n ceph_lv1 -l 100%FREE ceph_vg1
ceph orch daemon add osd ceph1:/dev/ceph_vg1/ceph_lv1

pvcreate /dev/sdb2
vgcreate ceph_vg2 /dev/sdb2
lvcreate -n ceph_lv2 -l 100%FREE ceph_vg2
ceph orch daemon add osd ceph1:/dev/ceph_vg2/ceph_lv2

pvcreate /dev/sdb3
vgcreate ceph_vg3 /dev/sdb3
lvcreate -n ceph_lv3 -l 100%FREE ceph_vg3
ceph orch daemon add osd ceph1:/dev/ceph_vg3/ceph_lv3

pvcreate /dev/sdb4
vgcreate ceph_vg4 /dev/sdb4
lvcreate -n ceph_lv4 -l 100%FREE ceph_vg4
ceph orch daemon add osd ceph1:/dev/ceph_vg4/ceph_lv4

pvcreate /dev/sdb5
vgcreate ceph_vg5 /dev/sdb5
lvcreate -n ceph_lv5 -l 100%FREE ceph_vg5
ceph orch daemon add osd ceph1:/dev/ceph_vg5/ceph_lv5

pvcreate /dev/sdb6
vgcreate ceph_vg6 /dev/sdb6
lvcreate -n ceph_lv6 -l 100%FREE ceph_vg6
ceph orch daemon add osd ceph1:/dev/ceph_vg6/ceph_lv6

pvcreate /dev/sdb7
vgcreate ceph_vg7 /dev/sdb7
lvcreate -n ceph_lv7 -l 100%FREE ceph_vg7
ceph orch daemon add osd ceph1:/dev/ceph_vg7/ceph_lv7

pvcreate /dev/sdb8
vgcreate ceph_vg8 /dev/sdb8
lvcreate -n ceph_lv8 -l 100%FREE ceph_vg8
ceph orch daemon add osd ceph1:/dev/ceph_vg8/ceph_lv8

pvcreate /dev/sdb9
vgcreate ceph_vg9 /dev/sdb9
lvcreate -n ceph_lv9 -l 100%FREE ceph_vg9
ceph orch daemon add osd ceph1:/dev/ceph_vg9/ceph_lv9
```
手动创建假的host，并把新添加的host移动到root下
```shell
ceph osd crush add-bucket ceph2 host
ceph osd crush add-bucket ceph3 host

ceph osd crush move ceph2 root=default
ceph osd crush move ceph3 root=default
```
把9个OSD平均分配到3个host中
```shell
for i in 1 4 7 ; do ceph osd crush move osd.$i host=ceph2 ; done
for i in 2 5 8 ; do ceph osd crush move osd.$i host=ceph3 ; done
```
此时发现集群状态依然警告
PG 状态异常，出现 [pg state unknown](https://www.cnblogs.com/deny/p/12886191.html)
```shell
[root@ceph1 ~]# ceph health detail
HEALTH_WARN Reduced data availability: 1 pg inactive
[WRN] PG_AVAILABILITY: Reduced data availability: 1 pg inactive
    pg 1.0 is stuck inactive for 41m, current state unknown, last acting []

[root@ceph1 ~]# ceph pg 1.0 query
Error ENOENT: i don`t have pgid 1.0

[root@ceph1 ~]# ceph osd force-create-pg 1.0
Error EPERM: This command will recreate a lost (as in data lost) PG with data in it, such that the cluster will give up ever trying to recover the lost data.  Do this only if you are certain that all copies of the PG are in fact lost and you are willing to accept that the data is permanently destroyed.  Pass --yes-i-really-mean-it to proceed.

[root@ceph1 ~]# ceph osd force-create-pg 1.0 --yes-i-really-mean-it
pg 1.0 now creating, ok
```

此命令或许也可行：
```shell
ceph pg repaire {pgid}
```
此后集群状态正常
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250313201859681.png)


参考文章：
[集群部署&监控 - 单节点Ceph配置 - 《Ceph学习笔记》 - 书栈网 · BookStack](https://www.bookstack.cn/read/zxj_ceph/one-mon-deploy)
[故障：pg state unknown - 流年晕开时光 - 博客园](https://www.cnblogs.com/deny/p/12886191.html)
[添加Ceph OSDs (LVM卷) — Cloud Atlas: Discovery beta 文档](https://cloud-atlas.readthedocs.io/zh-cn/latest/ceph/deploy/install_ceph_manual/add_ceph_osds_lvm.html)
chatGPT:

> [!NOTE]
> 从错误信息中可以看到，主要的问题出现在 `ceph-volume lvm batch` 命令执行时。错误信息提示：
> 
> ```
> ceph-volume lvm batch: error: /dev/sdb1 is a partition, please pass LVs or raw block devices
> ```
> 
> ### 问题原因：
> `ceph-volume` 工具要求你传递的设备应该是原始的块设备（raw block device），而不是一个分区（如 `/dev/sdb1`）。因为 `/dev/sdb1` 是一个已经分区的设备，所以不能直接用于创建 OSD。
> 
> ### 解决办法：
> 1. **使用裸设备**：你可以使用整个磁盘而不是一个分区。例如，如果你有 `/dev/sdb` 作为整个磁盘设备，可以尝试以下命令：
>    ```bash
>    ceph orch daemon add osd ceph1:/dev/sdb
>    ```
> 
> 2. **使用逻辑卷（LVM）**：如果你需要使用分区，你必须先将该分区作为逻辑卷使用。例如，如果你想使用 `/dev/sdb1`，你可以先创建一个 LVM 逻辑卷，并将其传递给 `ceph-volume`。步骤如下：
>    - 创建物理卷：
>      ```bash
>      pvcreate /dev/sdb1
>      ```
>    - 创建卷组：
>      ```bash
>      vgcreate ceph_vg /dev/sdb1
>      ```
>    - 创建逻辑卷：
>      ```bash
>      lvcreate -n ceph_lv -l 100%FREE ceph_vg
>      ```
>    - 然后，使用 `ceph-volume` 来创建 OSD，指向逻辑卷：
>      ```bash
>      ceph orch daemon add osd ceph1:/dev/ceph_vg/ceph_lv
>      ```
> 
> 2. **使用裸设备（Raw Block Device）来避免分区**：如果你不想使用 LVM 方式，你也可以选择使用整个磁盘，而不是分区。
> 
> ### 总结：
> - 错误发生的原因是 Ceph 期望传递给 `ceph-volume` 的是裸设备或逻辑卷，而不是分区。
> - 你可以选择使用整个磁盘 `/dev/sdb` 或者创建 LVM 逻辑卷并指定逻辑卷路径。
> 
> 希望这些信息对你有帮助！