# VIM编辑器

命令模式: ESC

插入模式: i o a A

退出模式: :



命令模式下:

a : 行首,并进入插入模式

A : 行尾,并进入插入模式

o : 在光标的下一行插入空行并进入插入模式

O : 在光标的上一行插入空行并进入插入模式

gg : 跳到行首

GG : 跳到行尾

15G 

ctrl + -> 一次移动一个单词

5 + 下箭头

pgup pgdn

dd 剪切

yy 复制  5yy 一次复制

p 粘贴

u 撤回

cc 删除光标所在的一行并进入插入模式

/xx 搜索  

​	n向下查找 N向上查找  

​	乱敲一通去除搜索

​	:set ignorecase 忽略大小写  noignorecase取消忽略

:w /root/newfile  另存为其他文件

:m,nw  把m行到n行另存到指定文件中

:%s/root/boot/gi 替换,g参数全局替换

:1,5s/root/boot/gi 替换,g参数全局替换



v选中模式

![{CC67FC48-687E-4A8C-89E5-6585F0C06B97}](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20241221143219704.png)



ctrl + w, s横向分割屏幕   ctrl + w, 上\下箭头  切换屏幕

ctrl + w, v纵向分割屏幕   ctrl + w, 左\右箭头  切换屏幕



临时文件

( R ) 恢复



退出模式下

:15 跳到15行

: set nu 显示行号  nonu

