DNS：域名名称系统

主机解析

正向解析：将计算机名装换成IP地址

反向解析：将IP地址装换成计算机名



智能DNS

二、DNS工作原理

‘ . ’ ：根域名



迭代查询：

![{3506A18A-5B3C-412A-823B-2B241A837BF0}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143349270.png)

yum install bind

systemctl reload named





$TTL 3H
@   IN SOA  @ rname.invalid. (
                    0   ; serial
                    1D  ; refresh
                    1H  ; retry
                    1W  ; expire
                    3H )    ; minimum
    NS  @
    A   127.0.0.1
    AAAA    ::1



named-checkzone yutianedu.com /var/named/yutianedu.zone



```shell
$TTL 1D
@    IN  SOA  ns1.zhangqifei.top. me.zhangqifei.top ( 0 1H 10M 1D 3H)
     IN  NS   ns1.zhangqifei.top
     IN  NS   ns2
         MX 10 mail1
         MX 20 mail2
ns1.zhangqifei.top  IN  A  192.168.111.254
ns2  IN  A  192.168.111.253  
db1   A    192.168.111.100
db2   A    192.168.111.111
web1  A    192.168.111.200
web2  A    192.168.111.222
mail1 A    192.168.111.10
mail2 A    192.168.111.20
www   CNAME   web1



$TTL 1D
@   IN  SOA ns1.magedu.com. me.zhangqifei.top (
                    20170001
                    1H
                    5M
                    7D
                    1D)
    IN NS ns1.zhangqifei.top.
    IN NS ns2.zhangqifei.top.
254 IN PTR ns1.zhangqifei.top.
253 IN PTR ns2.zhangqifei.top.
100 IN PTR db1.magedu.com.
111 IN PTR db2.magedu.com.
200 IN PTR web1.magedu.com.
222 IN PTR web2.magedu.com.
10  IN PTR mail1.magedu.com.
20  IN PTR mail2.magedu.com.
```



