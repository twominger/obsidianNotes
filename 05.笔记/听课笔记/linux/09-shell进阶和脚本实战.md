for 循环

for i in a b c d e

do 

​		somrthing

done

![{39C025DE-0558-478C-B5EB-1DBC789496F5}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143237708.png)



echo \$?   判断上一条命令是否执行成功,成功则返回0,不成功则返回非0.

&> /dev/null   不显示命令执行的过程

ping -c2 192.168.8.102 &> /dev/null

echo \$?   ($?仅判断**上一条**命令执行的结果)

cmd1 && cmd2 :cmd1执行成功了才执行cmd2,cmd1执行失败则运算结束

cmd1 || cmd2 :cmd1执行成功则运算结束,cmd1执行失败则执行cmd2

cmd1 ; cmd2 : cmd1执行后执行cmd2,不管是否执行成功 

if [ 运算 ]; then

​		something

fi



test 命令(用来检查文件类型或比较某一个值返回真或假)  

test \$A = \$B

test -f ping.sh

[ 命令 ]

[ “\$A” = “\$B” ]

[ -f “ping.sh” ]

```shell
       ( EXPRESSION )
              EXPRESSION is true

       ! EXPRESSION
              EXPRESSION is false

       EXPRESSION1 -a EXPRESSION2
              both EXPRESSION1 and EXPRESSION2 are true

       EXPRESSION1 -o EXPRESSION2
              either EXPRESSION1 or EXPRESSION2 is true

       -n STRING
              the length of STRING is nonzero
       STRING equivalent to -n STRING
       		  
       -z STRING
              the length of STRING is zero
              
       STRING1 = STRING2
              the strings are equal
              
       STRING1 != STRING2
              the strings are not equal

       INTEGER1 -eq INTEGER2
              INTEGER1 is equal to INTEGER2

       INTEGER1 -ge INTEGER2
              INTEGER1 is greater than or equal to INTEGER2

       INTEGER1 -gt INTEGER2
              INTEGER1 is greater than INTEGER2

       INTEGER1 -le INTEGER2
              INTEGER1 is less than or equal to INTEGER2

       INTEGER1 -lt INTEGER2
              INTEGER1 is less than INTEGER2

       INTEGER1 -ne INTEGER2
              INTEGER1 is not equal to INTEGER2

       FILE1 -ef FILE2
              FILE1 and FILE2 have the same device and inode numbers

       FILE1 -nt FILE2
              FILE1 is newer (modification date) than FILE2

       FILE1 -ot FILE2
              FILE1 is older than FILE2

       -b FILE
              FILE exists and is block special

       -c FILE
              FILE exists and is character special

       -d FILE
              FILE exists and is a directory

       -e FILE
              FILE exists

       -f FILE
              FILE exists and is a regular file

       -g FILE
              FILE exists and is set-group-ID

       -G FILE
              FILE exists and is owned by the effective group ID

       -h FILE
              FILE exists and is a symbolic link (same as -L)

       -k FILE
              FILE exists and has its sticky bit set

       -L FILE
              FILE exists and is a symbolic link (same as -h)

       -O FILE
              FILE exists and is owned by the effective user ID

       -p FILE
              FILE exists and is a named pipe

       -r FILE
              FILE exists and read permission is granted

       -s FILE
              FILE exists and has a size greater than zero

       -S FILE
              FILE exists and is a socket

       -t FD  file descriptor FD is opened on a terminal

       -u FILE
              FILE exists and its set-user-ID bit is set

       -w FILE
              FILE exists and write permission is granted

       -x FILE
              FILE exists and execute (or search) permission is granted

       Except for -h and  -L,  all  FILE-related  tests  dereference  symbolic  links.
       Beware  that  parentheses need to be escaped (e.g., by backslashes) for shells.
       INTEGER may also be -l STRING, which evaluates to the length of STRING.
NOTE: Binary -a and -o are inherently  ambiguous.   Use  'test  EXPR1  &&  test
       EXPR2' or 'test EXPR1 || test EXPR2' instead.

       NOTE:  [  honors  the  --help  and  --version options, but test does not.  test
       treats each of those as it treats any other nonempty STRING.

       NOTE: your shell may have its own version  of  test  and/or  [,  which  usually
       supersedes the version described here.  Please refer to your shell's documenta‐
       tion for details about the options it supports.

```



**if 判断语句-单分支结构**

``` shell 
if [ 条件 ]; then

	命令1

elif [ 条件 ]; then

	命令2

......

else 

	命令3

fi
```



crontab 计划任务

复合指令：

( ) 在子shell中进行

{ } 在当前shell中进行

``` shell
()
```



``` shell
(cal 2024 ; cal 2025) > cal.txt
```



while循环，条件成立时进行循环，最后一次条件成立时循环一次

``` shell
while [ 条件 ]
do 
	command 1
	command 2
	command 3
	...
done
```

![{42A7344E-61A4-450F-99D3-191D37BF07DF}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143237709.png)







until循环,条件成立时结束循环，最后一次条件成立时跳出循环

``` shell 
until [ 条件 ]
do 
	command 1
	command 2
	command 3
	...
done
```



break 跳出一层循环

continue 跳过本次循环，进行下一次循环

![{4E9033C0-4C9C-4259-BB4C-6578CEF4ABCE}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143237710.png)

![{2DD166AE-8BD6-46B5-9D4C-FBDFA86BA8EF}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143237711.png)

![{A583C3D6-02BD-4475-9893-74777258D9DC}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143237712.png)

