# Linux基本使用及语法



root管理员，唯一，其他均为普通用户

系统安装中设置了root密码，创建了一个普通用户



**设置计算机名**

hostnamectl set-hostname web01  ##修改主机名为web01(需要管理员权限)  
gggg
jjj
jnjkbjbkb  
hiuhih

exit ##退出终端/注销用户

hostname ##查询主机名

 ~ 用户所在的工作目录（默认/home）

\#当前用户为管理员

￥当前用户为普通用户



**关机：**

\#init 0

\#shutdown -h now

\#power off

**重启**

\#init 6

\#shutdown -r now

\#reboot



**web页面登录**

启动命令：systemctl enable —now  cockpit.socket

或者 systemctl start cockpit.service

浏览器访问：http://ip地址：9090



**设置时区**

timedatectl set-timezone “xxxx”

**查看某年的日历**

cal 11 2024  (2024年11月)



**创建新用户**(普通用户无法创建新用户)
id admin  (判断用户是否存在)
useradd admin  (创建用户) 
id admin  (判断创建用户是否成功)
passwd redhat  (设置密码,管理员无视密码限制,普通用户有限制)
echo redhat|passwd --stdin admin  (设置密码)
普通用户忘记密码,管理员有权限重置



**vim文本编辑器**

Linux系统中一切皆文件

vim是vi的升级版,最小化安装只有vi没有vim,需要安装

i :进入编辑模式

ESC :退出编辑模式

:wq :保存退出

:wq! :强制保存并推出(需要有权限,用户对目录有修改权限但是对目录下的文件没有修改权限)

:w :保存

:q :退出(未对文件进行修改)

:q! :强制退出 不保存更改



未退出的时候可以ESC按‘ U ’撤销;



**tab键一键补全**

两次显示所有命令



rpm -qa |grep bash-com 



**查看历史记录**

history  (用户正常关机才会保存,用户独立历史记录,存放在~/.bash_history)

!100  (调用第100条命令)

!v  (运行历史记录里面最近一条以v开头的命令)

最多保存1000条超出覆盖,/etc/profile中HISTSIZE=1000修改保存上限

history -c清空历史记录



**Linux语法规则**

命令  选项  参数  (每部分空格隔开) 

选项:

-a 

-a -b -c  (空格隔开)

-abc  ==  -a -b -c

\- - help  (两个段杠表示不可拆分)

参数:

空格隔开







**查询Linux命令的帮助**

whatis

command \--help  (更简洁)



**man** (manual更详细,回车键翻一行,空格键翻一页,q退出)

​	实际上是打开/usr/share/man中的文件

![{7454C849-FCF9-4F46-B73E-2345AAA51936}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143151415.png)

![{00DA63C1-7267-4629-9DD1-4F558E4C4622}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143151416.png)

/搜索词,回车搜索   小写n下一个,大写N上一个

**例子:**

NAME
       date - print or set the system date and time

**SYNOPSIS**一定要注意[ ]里面是否有特殊字符,包括空格,+,等等,需要在写命令的时候加上
       date [OPTION]**...** [+FORMAT]
       date [-u|--utc|--universal] \[MMDDhhmm\[[CC\]YY\][.ss]]

\[ ]: 可选项 (可选可不选)

cp [OPTION]... [-T] **SOURCE DEST**

语法大写字母: 必选项

…列表,可多选

date +"%Y-%m-%d --- %H:%M:%S"
2024-10-24 --- 15: 25:45

date -d '1 day ago' +"%Y-%m-%d --- %H-%M-%S"
2024-10-23 --- 15-31-24
date -d '1 week ago' +"%Y-%m-%d --- %H-%M-%S"
2024-10-17 --- 15-31-39
date -d '1 weeks ago' +"%Y-%m-%d --- %H-%M-%S"
2024-10-17 --- 15-31-51

应用场景,例如以昨天的日期时间命名

一天86400秒



**[-u|--utc|--universal]        a | b | c :多选一**

Coordinated Universal Time (UTC)  : 世界协调时间

UTC + 时区 == 当前系统显示的时间



**\[MMDDhhmm\[[CC\]YY\][.ss]]**

MMDDhhmm挨在一起必须同时一起写



info

pinfo

/usr/share/doc



cal  日历 


