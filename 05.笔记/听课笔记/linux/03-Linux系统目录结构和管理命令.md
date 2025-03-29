### Linux文件系统管理



windows

每个分区就是一个操作系统

Windows NTFS NT内核 Windows NT4.0  FileSystem 文件系统

Linux  ext2  ext3  ext4(适用于小文件场景) xfs(默认,适用于大文件场景)

在Linux中,一切接文件,包括设备

/dev  设备 

硬盘SATA ,SAS, SSD,SCSI ———— /dev/sda  /dev/sdb  /dev/sdc 

/dev/sda 第一块SCSI协议的硬盘

/dev/sdb 第二块SCSI协议的硬盘

/dev/sda1  /dev/sda2  第一块硬盘的第一个分区

Nvme , SSD ———— /dev/nvme0p0  /dev/nvme0p0n1第一个分区



所有设备必须挂载才能使用

/dev/sda1 不能直接使用，必须挂载才能使用

/dev/sda1 /boot      C:

/dev/sda2 /home    D:

/dev/sda3 / 

Windows中每个分区是一个目录树，相互独立

Linux系统中，所有的文件系统都是一个目录树

可以理解为挂载相当于一个快捷方式，并不是一个新的目录



例子：

磁盘挂载之前就已经开始录像，部分录像存储到根目录下，把磁盘挂载之后，之前的录像占用了空间但不可视，磁盘被莫名其妙占用。

<img src="./assets/03-Linux%E7%B3%BB%E7%BB%9F%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84%E5%92%8C%E7%AE%A1%E7%90%86%E5%91%BD%E4%BB%A4.assets/%7B22F4613B-4BBB-4841-89F9-76E76C46A35C%7D.png" alt="{22F4613B-4BBB-4841-89F9-76E76C46A35C}" style="zoom: 67%;" />

区分：

/  根目录

/root  是root用户的家目录

/usr 软件等,占用内存最大

/usr/bin  可执行文件 binary,普通用户使用的命令

/usr/sbin  系统管理员使用的命令

/etc  配置文件(建议备份)



**文件命名规则**

所有字符都可以作为文件名,除了不能使用( / ) ,但是建议不使用特殊符号,如果有应该用引号引起来

Linux中没有拓展名的概念,有拓展名是方便看的,拓展名包括( . )也占文件名长度

最长255个字符,一个中文汉字 == 两个字符

Linux系统中文件,目录,命令严格区分大小写,命令基本小写

Windows系统中不区分



**相对路径和绝对路径**

相对路径: 容易出事,删文件的时候等等尽量检查下 当前目录 或 写绝对路径

.  当前目录

..  上一级目录

绝对路径: 写程序尽量使用绝对路径,便于移植





### 文件系统深入讲解

pwd : 显示当前目录

cd : 返回当前用户的家目录

ls列出目录下的内容

​	文件类型：7种

​	白色 : 普通文件

​	蓝色 : 目录

​	绿色 : 可执行文件,u+x

​	青色 : 快捷方式,链接文件

​	红底黄底色 :  具有特殊权限 s

-l : 缩写ll,查看文件详细信息

h : 更直观的显示,human reachable

-a : 不忽略以‘.’点开头的文件

rm -rf \* 不能删除隐藏文件,rm -rf .\*加点可以

ls -la: 

-R : 递归,连同目录及目录下的所有子文件

ls -ld /etc/ : 显示目录本身的详细信息

ls -lt : 以修改时间顺序显示



tar -zcvf /tmp/etc.tar.gz /etc/  打包这里的-zcvf顺序不能打乱

alias: 查看系统中所有的别名



**cp 拷贝文件和目录**

cp test.sh /tmp/ 权限,用有人,拥有组,时间戳都改变

-r / -R: 递归

-p : 保留权限,拥有人和时间戳

-d : 保留快捷方式本身,只拷贝链接

-a === -d -r -p : 保留所有



**mkdir 创建文件夹**

mkdir a/ 

mkdir -p a/b/c/d/  : 递归创建文件夹,parents

如果有则不能重复创建



**touch 创建空文件或更新时间戳**

stat abc.txt 查看文件的时间戳

![{561054B0-A748-48C9-B80A-6503B72E356E}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143159262.png)

​	Access Time : atime : 文件最后一次访问的时间,如果atime比mtime,ctime更新时,不会频繁更新atime,24小时以后才能更新,cat,vim q

​	Modify Time : mtime : 文件最后一次修改的时间,wq

​	Change Time : ctime : 文件状态(大小,权限,拥有人,  )最后一次变更的时间,wq

touch abc.txt 如果abc.txt已经存在则更新其时间戳,atime,mtime,ctime,全部更新

touch \*

-a : 仅更新atime

\-\-time=mtime -d ‘2024-10-18 09:00:00’ abc.txt  :  更新到指定时间

mtime改变则ctime一定改变



**rm删除文件或目录**

-r : 递归

-f : 强制删除

rmdir /tmp/  删除空文件夹,某些情况创建一个空文件夹后里面被自动填充,但是rm又没有权限删除(例如在/sys/fs/cgroup/下的任何一个文件夹如memory里面创建空文件夹),可以使用rmdir删除



**mv移动(剪切)或改名**

mv test.sh /tmp/ 保留状态

file test.sh 查看文件类型,与扩展名无关,不受影响