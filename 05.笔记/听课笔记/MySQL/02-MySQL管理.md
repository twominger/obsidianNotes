增删改查
```mysql

```
# 1. 服务管理

## 1.1 配置

```mysql

```
## 1.2 备份


# 2. 用户管理(user)

## 2.1 新建用户

```mysql
CREATE USER 'username'@'host' IDENTIFIED BY 'password';
```

- `username`：用户名
- `host`：可以从哪些主机连接。例如：
  - `localhost`仅允许本地登录
  - `%`：允许从任何主机连接
  - `192.168.80.%`：允许网段的主机登录
  - `192.168.80.123`：仅允许改主机登录
- `passwd`：密码；

**实例：**
``` mysql
CREATE USER 'zmm'@'%' IDENTIFIED BY 'redhat';
```

## 2.2 删除用户

```mysql
DROP USER 'username'@'host';
```

 **实例：**
```mysql
DROP USER 'zmm'@'%';
```

## 2.3 修改用户

### 2.3.1 修改用户密码

```mysql
ALTER USER 'username'@'host' IDENTIFIED BY 'new_password';
```

**实例：**
```mysql
ALTER USER 'zmm'@'%' IDENTIFIED BY '123456';
```



### 2.3.2 修改用户主机

方法一：修改`mysql.user`表的`host`字段

```mysql
#1.修改mysql.user表
UPDATE mysql.user
SET host = 'new_host'
WHERE user = 'username' AND host = 'old_host';
#2.刷新权限使修改生效
FLUSH PRIVILEGES;
```

方法二：删除用户，重新创建用户

```mysql
#1.删除用户
DROP USER 'username'@'old_host';
#2.创建新用户
CREATE USER 'username'@'new_host' IDENTIFIED BY 'password';
#3.授予权限
GRANT ALL PRIVILEGES ON *.* TO 'username'@'new_host';
#4.刷新权限
FLUSH PRIVILEGES;
```

方法三：使用 `REVOKE` 和 `GRANT` 语句

```mysql
#1.撤销现有权限
REVOKE ALL PRIVILEGES ON *.* FROM 'username'@'old_host';
#2.授予新权限
GRANT ALL PRIVILEGES ON *.* TO 'username'@'new_host' IDENTIFIED BY 'password';
#3.刷新权限
FLUSH PRIVILEGES;
```

## 2.4 查询用户



# 3. 权限管理

## 3.1 授权权限

```mysql
GRANT privileges ON database_name.* TO 'username'@'host';
```

- `privileges`：具体权限，如`ALL PRIVILEGES`, `SELECT`, `INSERT`, `UPDATE`, `DELETE`等
- `database_name.*`：授权的数据库或表。例如：
  - `database_name.*`：指定数据库的所有表
  - `database_name.table_nam`e：指定数据库的指定表
  - `*.*`：所有数据库的所有表
- `'username'@'host'`：指定用户和主机

> **实例：**
> 
> ```mysql
> GRANT ALL PRIVILEGES ON *.* TO 'zmm'@'%';
> ```



## 3.2 刷新权限



```mysql
FLUSH PRIVILEGES;
```



## 3.3 查询权限





## 3.4 撤销权限



# 4. 数据库管理(database)



## 4.1 新建数据库



## 4.2 删除数据库



## 4.3 修改数据库



## 4.4 查询数据库



# 5. 表管理



## 5.1 新建表



## 5.2 删除表



## 5.3 修改表



## 5.4 查询表



# 6. 视图管理







