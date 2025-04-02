#!/bin/bash
# 3 节点，8.4 minimal 安装，单网卡，NAT
# 所有节点必须配置静态IP，必须配置网关和DNS（以防因软硬件兼容性问题导致安装过程掉网）
# Auth: tianhairui
# 192.168.224.100 controller
# 192.168.224.101 compute1
# 192.168.224.102 compute2

# Conf /etc/hosts
echo "为当前 controller 节点配置映射关系..."
echo '192.168.224.100 controller' >> /etc/hosts
echo '192.168.224.101 compute1' >> /etc/hosts
echo '192.168.224.102 compute2' >> /etc/hosts
echo "当前 controller 节点映射关系配置完成"
cat /etc/hosts

echo "为当前 controller 节点关闭防火墙及SELinux..."
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
# sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop NetworkManager
systemctl disable NetworkManager
echo "当前 controller 节点防火墙及SELinux已关闭"

echo "为当前 controller 节点配置yum源..."
if [ ! -d /etc/yum.repos.d/bak ]; then
  echo "备份目录不存在，正在创建..."
  mkdir /etc/yum.repos.d/bak
  mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
else
  echo "备份目录已存在，正在移动原有repo文件..."
  mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
fi
cat <<EOF > /etc/yum.repos.d/cloudcs.repo
[BaseOS]
name = BaseOS
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/BaseOS/x86_64/os/
gpgcheck = 0

[AppStream]
name = AppStream
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/AppStream/x86_64/os/
gpgcheck = 0

[centos-advanced-virtualization]
name = centos-advanced-virtualization
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/virt/x86_64/advanced-virtualization/
gpgcheck = 0

[centos-ceph-pacific]
name = centos-ceph-nautilus
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/storage/x86_64/ceph-pacific/
gpgcheck = 0

[centos-nfv-openvswitch]
name = centos-nfv-openvswitch
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/nfv/x86_64/openvswitch-2/
gpgcheck = 0

[centos-openstack-victoria]
name = centos-openstack-victoria
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/cloud/x86_64/openstack-victoria/
gpgcheck = 0

[centos-rabbitmq-38]
name = centos-rabbitmq-38
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/messaging/x86_64/rabbitmq-38/
gpgcheck = 0

[extras]
name = extras
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/extras/x86_64/os/
gpgcheck = 0

[PowerTools]
name = PowerTools
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/PowerTools/x86_64/os/
gpgcheck = 0
EOF

echo "正在更新 controller 节点yum源..."
yum clean all
yum repolist all
echo "更新 controller 节点软件包..."
yum install -y vim net-tools bash-completion chrony.x86_64
yum install -y https://mirrors.aliyun.com/centos-vault/centos/8-stream/AppStream/x86_64/os/Packages/sshpass-1.09-4.el8.x86_64.rpm

echo "正在配置 controller 节点NTP..."
cp /etc/chrony.conf /etc/chrony.conf.bak
cat <<EOF > /etc/chrony.conf
server controller iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
allow 192.168.224.0/24
local stratum 10
EOF
systemctl start chronyd.service
systemctl enable chronyd.service

echo "controller 节点NTP 配置完成 :)"

# Def Remote Node
nodes=("compute1" "compute2")
user="root"
password="redhat"

# Gen SSH Key(If Not Exists)
if [ ! -f ~/.ssh/id_rsa ]; then
  echo "SSH 密钥不存在，正在生成..."
  ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
else
  echo "SSH 密钥已存在，跳过生成步骤。"
fi

# Send SSH Key To Remote Node
for node in "${nodes[@]}"; do
  echo "正在将公钥发送到 $node..."
  sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no "$user@$node"
  
  if [ $? -eq 0 ]; then
    echo "成功将公钥发送到 $node。"
  else
    echo "无法将公钥发送到 $node，请检查连接或权限。"
    exit 1
  fi
done

# 遍历每个节点并执行远程命令
for node in "${nodes[@]}"; do
  echo "正在连接到 $node 执行命令..."
  ssh -T "$user@$node" <<EOF
  echo "在 $node 执行以下命令："
  echo "配置 $node 主机名及ip映射："
  echo '192.168.224.100 controller' >> /etc/hosts
  echo '192.168.224.101 compute1' >> /etc/hosts
  echo '192.168.224.102 compute2' >> /etc/hosts
  cat /etc/hosts

  echo "正在关闭 $node 防火墙..."
  systemctl stop firewalld
  systemctl disable firewalld
  setenforce 0
  
  systemctl stop NetworkManager
  systemctl disable NetworkManager

  echo "配置 $node YUM源..."
  if [ ! -d /etc/yum.repos.d/bak ]; then
    echo "备份目录不存在，正在创建..."
    mkdir /etc/yum.repos.d/bak
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  else
    echo "备份目录已存在，正在移动原有repo文件..."
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  fi
  
  echo "正在为 $node 创建新的repo文件..."
  cat <<'EOF2' > /etc/yum.repos.d/cloudcs.repo
[BaseOS]
name = BaseOS
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/BaseOS/x86_64/os/
gpgcheck = 0

[AppStream]
name = AppStream
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/AppStream/x86_64/os/
gpgcheck = 0

[centos-advanced-virtualization]
name = centos-advanced-virtualization
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/virt/x86_64/advanced-virtualization/
gpgcheck = 0

[centos-ceph-pacific]
name = centos-ceph-nautilus
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/storage/x86_64/ceph-pacific/
gpgcheck = 0

[centos-nfv-openvswitch]
name = centos-nfv-openvswitch
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/nfv/x86_64/openvswitch-2/
gpgcheck = 0

[centos-openstack-victoria]
name = centos-openstack-victoria
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/cloud/x86_64/openstack-victoria/
gpgcheck = 0

[centos-rabbitmq-38]
name = centos-rabbitmq-38
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/messaging/x86_64/rabbitmq-38/
gpgcheck = 0

[extras]
name = extras
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/extras/x86_64/os/
gpgcheck = 0

[PowerTools]
name = PowerTools
baseurl = https://mirrors.aliyun.com/centos-vault/8.4.2105/PowerTools/x86_64/os/
gpgcheck = 0
EOF2
  
  echo "正在更新 $node yum源..."
  yum clean all
  yum repolist all

  echo "更新 $node 软件包..."
  yum install -y vim net-tools bash-completion chrony.x86_64
  #sudo apt-get update && sudo apt-get upgrade -y || echo "非 Debian/Ubuntu 系统，跳过更新。"

  echo "配置 $node NTP..."
cp /etc/chrony.conf /etc/chrony.conf.bak
cat <<'EOF3' > /etc/chrony.conf
server controller iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF3
systemctl start chronyd.service
systemctl enable chronyd.service

  echo "$node 正在向 controller 进行同步..."
  chronyc makestep
  sleep 5
  chronyc sources
  echo "$node 同步成功"
  echo "$node 的命令执行完成。"
EOF

  if [ $? -eq 0 ]; then
    echo "$node 的命令执行成功。"
  else
    echo "$node 的命令执行失败，请检查连接或权限。"
  fi
done

echo "controller 正在安装 packstack 工具..."
yum install -y openstack-packstack

echo "controller 正在创建应答文件..."
packstack --gen-answer-file=/root/cloudcs.txt

echo "controller 正在修改应答文件..."
sed -i '/^CONFIG_COMPUTE_HOSTS/ s/.*/CONFIG_COMPUTE_HOSTS=192.168.224.101,192.168.224.102/' /root/cloudcs.txt
sed -i '/^CONFIG_KEYSTONE_ADMIN_PW/ s/.*/CONFIG_KEYSTONE_ADMIN_PW=redhat/' /root/cloudcs.txt
sed -i 's/CONFIG_PROVISION_DEMO=y/CONFIG_PROVISION_DEMO=n/g' /root/cloudcs.txt
sed -i 's/CONFIG_NEUTRON_OVN_BRIDGE_IFACES=/CONFIG_NEUTRON_OVN_BRIDGE_IFACES=br-ex:ens160/g' /root/cloudcs.txt
sed -i 's/CONFIG_HEAT_INSTALL=n/CONFIG_HEAT_INSTALL=y/g' /root/cloudcs.txt

echo "controller 正在部署..."
sshpass -p "$password" packstack --answer-file=/root/cloudcs.txt 

#echo "禁用全局 ID（global_id）回收操作..."
# ceph config set mon auth_allow_insecure_global_id_reclaim false
# sleep 10
# echo "ceph01 查看当前集群状态..."
# ceph -s
# echo "初始化集群已创建好!"
# 
# read -p "是否继续执行扩容及开启UI界面操作？请输入 y 或 n: " choice
# 
# case "$choice" in
#     [Yy]*)
#         echo "执行mon扩容操作..."
#         ceph-deploy mon add ceph02 --address 192.168.224.102
#         ceph-deploy mon add ceph03 --address 192.168.224.103
#         echo "执行mgr扩容操作..."
#         ceph-deploy mgr create ceph02 ceph03
#         echo "正在启用dashboard服务..."
#         ceph mgr module enable dashboard
#         ceph config set mgr mgr/dashboard/ssl false
#         ceph config set mgr mgr/dashboard/server_addr 0.0.0.0
#         ceph config set mgr mgr/dashboard/server_port 5050
#         echo redhat > pass
#         ceph dashboard ac-user-create admin -i pass administrator
#         echo "正在重启mgr服务..."
#         systemctl restart ceph-mgr@ceph01.service
#         sleep 5
#         echo "UI访问地址及端口号为："
#         ceph mgr services
#         echo "账号：admin 密码：redhat"
#         echo "完成！"
#         ;;
#     [Nn]*)
#         echo "退出脚本。"
#         exit 0
#         ;;
#     *)
#         echo "无效的输入，请输入 y 或 n。"
#         exit 1
#         ;;
# esac

echo "controller 启动 network 服务"
/usr/lib/systemd/systemd-sysv-install enable network
systemctl start network

# 遍历每个节点并执行远程命令
for node in "${nodes[@]}"; do
  echo "正在连接到 $node 执行命令..."
  ssh -T "$user@$node" <<EOF
  echo "在 $node 启动 network 服务"
  /usr/lib/systemd/systemd-sysv-install enable network
  systemctl start network
EOF
done
echo "openstack 部署完成！"