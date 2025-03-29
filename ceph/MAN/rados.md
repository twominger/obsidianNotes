```shell
# POOL COMMANDS
lspools                           # 列出所有池
cppool <pool-name> <dest-pool>    # 复制一个池的内容到目标池
purge <pool-name> --yes-i-really-really-mean-it   # 从池 <pool-name> 中删除所有对象，但不删除池本身
df                                 # 显示每个池和总的使用情况
ls                                 # 列出池中的对象

# POOL SNAP COMMANDS
lssnap                             # 列出所有快照
mksnap <snap-name>                 # 创建快照 <snap-name>
rmsnap <snap-name>                 # 删除快照 <snap-name>

# OBJECT COMMANDS
get <obj-name> <outfile>           # 获取对象
put <obj-name> <infile> [--offset offset]   # 写入对象并设置起始偏移量（默认偏移量：0）
append <obj-name> <infile>         # 向对象追加数据
truncate <obj-name> length         # 截断对象
create <obj-name>                  # 创建对象
rm <obj-name> ... [--force-full]   # 删除对象，--force-full 强制在集群满时删除
cp <obj-name> [target-obj]         # 复制对象
listxattr <obj-name>               # 列出对象的扩展属性
getxattr <obj-name> attr           # 获取对象的指定扩展属性
setxattr <obj-name> attr val       # 设置对象的扩展属性
rmxattr <obj-name> attr            # 删除对象的扩展属性
stat <obj-name>                    # 获取对象的状态
stat2 <obj-name>                   # 获取对象的状态（高精度时间）
touch <obj-name> [timestamp]       # 修改对象的修改时间
mapext <obj-name>                  # 映射对象的扩展
rollback <obj-name> <snap-name>    # 将对象回滚到快照 <snap-name>

listsnaps <obj-name>               # 列出该对象的所有快照
bench <seconds> write|seq|rand [-t concurrent_operations] [--no-cleanup] [--run-name run_name] [--no-hints] [--reuse-bench]
                                  # 基准测试，默认是16个并发IO和4MB的操作，默认会在写入基准测试后清理，默认运行名称是 'benchmark_last_metadata'
cleanup [--run-name run_name] [--prefix prefix]  # 清理之前的基准测试操作，默认运行名称是 'benchmark_last_metadata'
load-gen [options]                 # 生成负载到集群
listomapkeys <obj-name>            # 列出对象映射中的所有键
listomapvals <obj-name>            # 列出对象映射中的所有键和值
getomapval <obj-name> <key> [file] # 获取指定键的值，存储到文件中
setomapval <obj-name> <key> <val | --input-file file>  # 设置对象映射中的指定键的值
rmomapkey <obj-name> <key>         # 删除对象映射中的指定键
clearomap <obj-name> [obj-name2 obj-name3...]  # 清除指定对象的所有omap键
getomapheader <obj-name> [file]    # 获取对象映射的头信息
setomapheader <obj-name> <val>     # 设置对象映射的头信息
watch <obj-name>                   # 为该对象添加监视器
notify <obj-name> <message>        # 向该对象的监视器发送消息
listwatchers <obj-name>            # 列出该对象的所有监视器
set-alloc-hint <obj-name> <expected-object-size> <expected-write-size>
                                  # 为对象设置分配提示
set-redirect <object A> --target-pool <caspool> <target object A> [--with-reference]
                                  # 设置重定向目标
set-chunk <object A> <offset> <length> --target-pool <caspool> <target object A> <taget-offset> [--with-reference]
                                  # 将对象转换为分块对象
tier-promote <obj-name>            # 将对象提升到基础层
unset-manifest <obj-name>          # 取消对象的重定向或分块设置
tier-flush <obj-name>              # 刷新分块对象
tier-evict <obj-name>              # 驱逐分块对象

```

```shell
IMPORT AND EXPORT
export [filename]  
   # 将池内容序列化到文件或标准输出。
import [--dry-run] [--no-overwrite] < filename | - >  
   # 从文件或标准输入加载池内容。

ADVISORY LOCKS
lock list <obj-name>  
   # 列出对象上的所有咨询锁。
lock get <obj-name> <lock-name> [--lock-cookie locker-cookie] [--lock-tag locker-tag] [--lock-description locker-desc] [--lock-duration locker-dur] [--lock-type locker-type]  
   # 尝试获取一个锁。
lock break <obj-name> <lock-name> <locker-name> [--lock-cookie locker-cookie]  
   # 尝试打破由其他客户端获取的锁。
lock info <obj-name> <lock-name>  
   # 显示锁的详细信息。
options:
   --lock-tag                   # 锁标签，所有锁操作应该使用相同的标签。
   --lock-cookie                # 锁定者的cookie。
   --lock-description           # 锁的描述。
   --lock-duration              # 锁的持续时间（单位：秒）。
   --lock-type                  # 锁类型（共享锁，排他锁）。

SCRUB AND REPAIR:
list-inconsistent-pg <pool>      # 列出给定池中的不一致PG。
list-inconsistent-obj <pgid>     # 列出给定PG中的不一致对象。
list-inconsistent-snapset <pgid> # 列出给定PG中的不一致快照集。

CACHE POOLS: (仅用于测试/开发)
cache-flush <obj-name>           # 刷新缓存池对象（阻塞）。
cache-try-flush <obj-name>       # 尝试刷新缓存池对象（非阻塞）。
cache-evict <obj-name>           # 驱逐缓存池对象。
cache-flush-evict-all            # 刷新并驱逐所有对象。
cache-try-flush-evict-all        # 尝试刷新并驱逐所有对象。

GLOBAL OPTIONS:
--object-locator object_locator  
   # 设置操作使用的对象定位器。
-p pool  
--pool=pool  
   # 选择给定名称的池。
--target-pool=pool  
   # 选择目标池的名称。
--pgid PG id  
   # 选择给定PG ID。
-f [--format plain|json|json-pretty]  
   # 设置输出格式（plain、json 或 json-pretty）。
-b op_size  
   # 设置put/get操作和写入基准测试的块大小。
-O object_size  
   # 设置put/get操作和写入基准测试的对象大小。
--max-objects  
   # 设置写入基准测试的最大对象数。
--obj-name-file file  
   # 使用指定文件的内容代替<obj-name>。
-s name  
--snap name  
   # 选择给定的快照名称进行（读取）IO。
--input-file file  
   # 使用指定文件的内容代替<val>。
--create  
   # 创建指定的池或目录。
-N namespace  
--namespace=namespace  
   # 指定操作使用的命名空间。
--all  
   # 使用ls时列出所有命名空间中的对象。可以通过将其放入CEP_ARGS环境变量来设置为默认值。
--default  
   # 使用ls时列出默认命名空间中的对象。优先于--all环境变量中的设置。
--target-locator  
   # 使用cp命令时指定新对象的定位器。
--target-nspace  
   # 使用cp命令时指定新对象的命名空间。
--striper  
   # 使用radostriper接口，而非纯rados，适用于stat、get、put、truncate、rm、ls和所有xattr相关操作。

BENCH OPTIONS:
-t N  
--concurrent-ios=N  
   # 设置并发I/O操作数。
--show-time  
   # 在输出前加上日期/时间戳。
--no-verify  
   # 不验证读取对象的内容。
--write-object  
   # 将内容写入对象。
--write-omap  
   # 将内容写入omap。
--write-xattr  
   # 将内容写入扩展属性。

LOAD GEN OPTIONS:
--num-objects                    # 总对象数。
--min-object-size                # 最小对象大小。
--max-object-size                # 最大对象大小。
--min-op-len                     # 操作的最小I/O大小。
--max-op-len                     # 操作的最大I/O大小。
--max-ops                        # 最大操作数。
--max-backlog                    # 最大积压大小。
--read-percent                   # 读取操作的百分比。
--target-throughput              # 目标吞吐量（单位：字节）。
--run-length                     # 总运行时间（单位：秒）。
--offset-align                   # 随机操作偏移量的对齐边界。

CACHE POOLS OPTIONS:
--with-clones                    # 在执行刷新或驱逐时包含克隆。

OMAP OPTIONS:
--omap-key-file file            # 从文件读取omap键。

GENERIC OPTIONS:
--conf/-c FILE    # 从指定的配置文件读取配置。
--id ID           # 设置ID部分的名称。
--name/-n TYPE.ID # 设置名称。
--cluster NAME    # 设置集群名称（默认为ceph）。
--setuser USER    # 设置uid为用户或uid（并将gid设置为用户的gid）。
--setgroup GROUP  # 设置gid为组或gid。
--version         # 显示版本并退出。

```


