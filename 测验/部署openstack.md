```shell
hostnamectl set-hostname controller
nmcli connection modify ens160 ipv4.addresses 192.168.44.100/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
```

![[附件/centos8.4_openstack_victoria.sh]]

```shell
chmod +x centos8.4_openstack_victoria.sh 
./centos8.4_openstack_victoria.sh 
```

```shell
controller 正在创建应答文件...
Additional information:
 * Parameter CONFIG_NEUTRON_L2_AGENT: You have chosen OVN Neutron backend. Note that this backend does not support the VPNaaS plugin. Geneve will be used as the encapsulation method for tenant networks
controller 正在修改应答文件...
controller 正在部署...
Welcome to the Packstack setup utility

The installation log file is available at: /var/tmp/packstack/20250402-000209-jp4k63yu/openstack-setup.log

Installing:
Clean Up                                             [ DONE ]
Discovering ip protocol version                      [ DONE ]
Setting up ssh keys                                  [ DONE ]
Preparing servers                                    [ DONE ]
Pre installing Puppet and discovering hosts' details [ DONE ]
Preparing pre-install entries                        [ DONE ]
Setting up CACERT                                    [ DONE ]
Preparing AMQP entries                               [ DONE ]
Preparing MariaDB entries                            [ DONE ]
Fixing Keystone LDAP config parameters to be undef if empty[ DONE ]
Preparing Keystone entries                           [ DONE ]
Preparing Glance entries                             [ DONE ]
Checking if the Cinder server has a cinder-volumes vg[ DONE ]
Preparing Cinder entries                             [ DONE ]
Preparing Nova API entries                           [ DONE ]
Creating ssh keys for Nova migration                 [ DONE ]
Gathering ssh host keys for Nova migration           [ DONE ]
Preparing Nova Compute entries                       [ DONE ]
Preparing Nova Scheduler entries                     [ DONE ]
Preparing Nova VNC Proxy entries                     [ DONE ]
Preparing OpenStack Network-related Nova entries     [ DONE ]
Preparing Nova Common entries                        [ DONE ]
Preparing Neutron API entries                        [ DONE ]
Preparing Neutron L3 entries                         [ DONE ]
Preparing Neutron L2 Agent entries                   [ DONE ]
Preparing Neutron DHCP Agent entries                 [ DONE ]
Preparing Neutron Metering Agent entries             [ DONE ]
Checking if NetworkManager is enabled and running    [ DONE ]
Preparing OpenStack Client entries                   [ DONE ]
Preparing Horizon entries                            [ DONE ]
Preparing Swift builder entries                      [ DONE ]
Preparing Swift proxy entries                        [ DONE ]
Preparing Swift storage entries                      [ DONE ]
Preparing Heat entries                               [ DONE ]
Preparing Heat CloudFormation API entries            [ DONE ]
Preparing Gnocchi entries                            [ DONE ]
Preparing Redis entries                              [ DONE ]
Preparing Ceilometer entries                         [ DONE ]
Preparing Aodh entries                               [ DONE ]
Preparing Puppet manifests                           [ DONE ]
Copying Puppet modules and manifests                 [ DONE ]
Applying 192.168.44.100_controller.pp
192.168.44.100_controller.pp:                        [ DONE ]           
Applying 192.168.44.100_network.pp
192.168.44.100_network.pp:                           [ DONE ]        
Applying 192.168.44.101_compute.pp
Applying 192.168.44.102_compute.pp
192.168.44.101_compute.pp:                           [ DONE ]        
192.168.44.102_compute.pp:                           [ DONE ]        
Applying Puppet manifests                            [ DONE ]
Finalizing                                           [ DONE ]

 **** Installation completed successfully ******

Additional information:
 * Parameter CONFIG_NEUTRON_L2_AGENT: You have chosen OVN Neutron backend. Note that this backend does not support the VPNaaS plugin. Geneve will be used as the encapsulation method for tenant networks
 * Time synchronization installation was skipped. Please note that unsynchronized time on server instances might be problem for some OpenStack components.
 * File /root/keystonerc_admin has been created on OpenStack client host 192.168.44.100. To use the command line tools you need to source the file.
 * To access the OpenStack Dashboard browse to http://192.168.44.100/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
 * The installation log file is available at: /var/tmp/packstack/20250402-000209-jp4k63yu/openstack-setup.log
 * The generated manifests are available at: /var/tmp/packstack/20250402-000209-jp4k63yu/manifests
controller 启动 network 服务
正在连接到 compute1 执行命令...
在 compute1 启动 network 服务
正在连接到 compute2 执行命令...
在 compute2 启动 network 服务
openstack 部署完成！

```