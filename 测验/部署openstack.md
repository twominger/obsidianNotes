```shell
hostnamectl set-hostname controller
nmcli connection modify ens160 ipv4.addresses 192.168.44.100/24 ipv4.gateway 192.168.44.2 ipv4.dns 114.114.114.114 ipv4.method manual autoconnect yes
systemctl restart NetworkManager
nmcli connection reload
nmcli connection down ens160
nmcli connection up ens160
```

![[100.附件/centos8.4_openstack_victoria.sh]]

```shell
chmod +x centos8.4_openstack_victoria.sh 
./centos8.4_openstack_victoria.sh 
```

