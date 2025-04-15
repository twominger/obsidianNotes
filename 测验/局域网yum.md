- 下载yum源增加rpm包工具
```shell
yum install createrepo -y
```
- 下载rpm包到指定目录下 如：
```shell
yum install nginx --downloadonly --downloaddir=/centos8/zmm/Packages/
```
- 每加入一个rpm包就要更新一下
```shell
createrepo --update /centos8/zmm/
```
![[100.附件/addrepo]]
```shell

#!/bin/bash

# Define repository and package directory
repodir="/centos8"
packagedir=""

# Check if one argument (package name) is passed
if [[ "$#" -eq 1 ]]; then
    packagedir="${repodir}/${1}"  # Set packagedir based on package name
else
    echo "Usage: $0 <package-name>"
    exit 1
fi

# Clean up /tmp/repo if it exists
if [[ -d /tmp/repo ]]; then
    rm -rf /tmp/repo/*
else
    mkdir -p /tmp/repo
fi

# Download the package to /tmp/repo
yum -y install ${1} --downloadonly --downloaddir=/tmp/repo

# Check if the package directory exists, if not, create it
if [[ -d ${packagedir} ]]; then
    rm -rf "${packagedir}/*"  # Clean existing packages if any
else
    mkdir -p "${packagedir}/Packages"  # Create Packages subdirectory if it doesn't exist
fi

# Move the downloaded packages to the package directory
mv /tmp/repo/* "${packagedir}/Packages/"

# Create or update the repository
createrepo --update ${packagedir}

# Check if createrepo was successful
if [[ $? -eq 0 ]]; then
    echo "Repository updated successfully at ${packagedir}"
else
    echo "Error updating repository"
    exit 1
fi
```


```shell
mkdir /etc/yum.repos.d/bak2
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak2/
wget http://192.168.224.113/centos8/a.repo -O /etc/yum.repos.d/a.repo
yum clean all
yum makecache
```

```shell
mkdir /etc/yum.repos.d/bak2
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak2/
cat >/etc/yum.repos.d/local.repo <<EOF
[AppStream]
name = AppStream
baseurl = http://192.168.224.113/media/AppStream
gpgcheck = 0

[BaseOS]
name = BaseOS
baseurl = http://192.168.224.113/media/BaseOS
gpgcheck = 0
EOF
yum clean all
yum makecache
```

openstack 实例调整大小
```shell
source keystonerc_admin
openstack server list --all
# +--------------------------------------+--------+-----------+--------------------------------------+--------------------------+------------------+
# | ID                                   | Name   | Status    | Networks                             | Image                    | Flavor           |
# +--------------------------------------+--------+-----------+--------------------------------------+--------------------------+------------------+
# | 9e8f8577-35c6-44a1-976b-5039b2f30867 | discuz | SUSPENDED | private=172.17.10.91, 192.168.224.96 | N/A (booted from volume) | discuz           |
# | 92fd9211-8f0f-4d2f-a5f5-7a2e0b53fb04 | n02    | ACTIVE    | private=172.17.10.88, 192.168.224.92 | N/A (booted from volume) | container_flavor |
# | e7fe54f2-6693-4724-9eef-f7bba70d24c8 | n01    | ACTIVE    | private=172.17.10.89, 192.168.224.86 | N/A (booted from volume) | centos8_4        |
# | 84d346d2-9edf-49cd-9e64-617307d493ea | m03    | ACTIVE    | private=172.17.10.99, 192.168.224.93 | N/A (booted from volume) | centos8_4        |
# | 7a3b46f0-cf36-4299-9c0c-0604efda8cb6 | m02    | ACTIVE    | private=172.17.10.97, 192.168.224.98 | N/A (booted from volume) | centos8_4        |
# | 4094fe52-085e-44c2-b672-09171d1681b2 | sql03  | SUSPENDED | private=172.17.10.90, 192.168.224.97 | N/A (booted from volume) | centos8_4        |
# | 4974c4c1-7343-4056-b7a6-5e7aca1f2012 | sql02  | SUSPENDED | private=172.17.10.98, 192.168.224.91 | N/A (booted from volume) | centos8_4        |
# | 7f6c8587-460c-4c9f-9cdb-1f7ce45775ca | m01    | SHUTOFF   | private=172.17.10.94, 192.168.224.95 | N/A (booted from volume) | centos8_4        |
# | 45649f27-2d14-49dc-84d2-4abd44c39d7b | sql01  | SUSPENDED | private=172.17.10.86, 192.168.224.82 | N/A (booted from volume) | centos8_4        |
# | 010d2c43-c77c-4b99-9b0f-b4a1a0ac2390 | harbor | SUSPENDED | private=172.17.10.81, 192.168.224.94 | N/A (booted from volume) | centos8_4        |
# +--------------------------------------+--------+-----------+--------------------------------------+--------------------------+------------------+

openstack flavor list
# +--------------------------------------+--------------------+------+------+-----------+-------+-----------+
# | ID                                   | Name               |  RAM | Disk | Ephemeral | VCPUs | Is Public |
# +--------------------------------------+--------------------+------+------+-----------+-------+-----------+
# | 362d42cc-b2bd-459b-b105-a63f78c4feb3 | container_flavor   | 4096 |   15 |         0 |     2 | True      |
# | 573bc1f2-861f-49e7-acf1-f36f3aaa9aad | cirros             |  512 |    1 |         0 |     1 | True      |
# | 6b5e2821-fbfa-4cbb-a68e-236f37237793 | discuz             | 1024 |   10 |         0 |     1 | True      |
# | 96c99187-34f3-46f1-aa13-6201bb5fea45 | centos8_4          | 2048 |   10 |         0 |     1 | True      |
# | c64eabbf-b56b-40ac-b5c4-fd75a6cc6efc | container_flavor02 | 2048 |   10 |         0 |     2 | True      |
# +--------------------------------------+--------------------+------+------+-----------+-------+-----------+
openstack server resize --flavor container_flavor02 m01

```