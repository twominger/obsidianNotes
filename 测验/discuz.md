```shell
git clone https://gitee.com/Discuz/DiscuzX.git
```

```shell
set sql_log_bin=0;
grant replication slave on *.* to repl@'192.168.44.%' identified by '123456';
flush privileges;
set sql_log_bin=1;
```


![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327173314404.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327173958525.png)

```shell
[root@discuz data]# pwd 
/var/www/html/install/data
[root@discuz data]# vim install.sql 
```
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327173550048.png)
```shell
1389 DROP TABLE IF EXISTS pre_common_statuser;
1390 CREATE TABLE pre_common_statuser (
1391   uid mediumint(8) unsigned NOT NULL DEFAULT '0',
1392   daytime int(10) unsigned NOT NULL DEFAULT '0',
1393   `type` char(20) NOT NULL DEFAULT '',
1394   PRIMARY KEY (uid)
1395 ) ENGINE=InnoDB;
```

```shell

```
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327174952181.png)


![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327175059131.png)

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327175223185.png)

![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327175338476.png)


![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327180012213.png)



![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250327181037833.png)


