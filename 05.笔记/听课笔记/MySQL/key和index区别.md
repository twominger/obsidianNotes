Mysql 的 key 和 index 多少有点令人迷惑，这实际上考察对数据库体系结构的了解的。  

1). Key 是数据库的物理结构，它包含两层意义，一是约束（偏重于约束和规范数据库的结构完整性），二是索引（辅助查询用的）。包括 primary key, unique key, foreign key 等。  

Primary key 有两个作用，一是约束作用（constraint），用来规范一个存储主键和唯一性，但同时也在此 key 上建立了一个 index；
Unique key 也有两个作用，一是约束作用（constraint），规范数据的唯一性，但同时也在这个 key 上建立了一个 index；
Foreign key 也有两个作用，一是约束作用（constraint），规范数据的引用完整性，但同时也在这个 key 上建立了一个 index；

可见，mysql 的 key 是同时具有 constraint 和 index 的意义，这点和其他数据库表现的可能有区别。（至少在[Oracle](http://lib.csdn.net/base/oracle "Oracle 知识库") 上建立外键，不会自动建立 index），因此创建 key 也有如下几种方式：
（1）在字段级以 key 方式建立，如 create table t (id int not null primary key);
（2）在表级以 constraint 方式建立，如 create table t (id int, CONSTRAINT pk_t_id PRIMARY key (id));
（3）在表级以 key 方式建立，如 create table t (id int, primary key (id));  
其它 key 创建类似，但不管那种方式，既建立了 constraint，又建立了 index，只不过 index 使用的就是这个 constraint 或 key。
  
index是数据库的物理结构，它只是辅助查询的，它创建时会在另外的表空间（mysql中的innodb表空间）以一个类似目录的结构存储。索引要分类的话，分为前缀索引、全文本索引等；

因此，索引只是索引，它不会去约束索引的字段的行为（那是 key 要做的事情）。  
如，create table t (id int, index inx_tx_id  (id));