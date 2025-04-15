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
```