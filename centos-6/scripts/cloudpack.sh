yum update -y
cat << EOT >> /etc/cloud/cloud.cfg.d/99-cloudpack.cfg
locale: en_US.UTF-8
datasource_list: [Ec2]
datasource:
  Ec2:
    metadata_urls: ['http://169.254.169.254']

fs_setup:
  - label: ephemeral1,
    filesystem: ext3
    extra_opts: [ "-E", "nodiscard" ]
    device: ephemeral1
    partition: auto

mounts:
  - [ /dev/xvdc, /mnt/ephemeral/1 ]
EOT

cat << EOT >> /etc/yum.conf
exclude=bash*
EOT

yum install -y bc strace mtr dstat sysstat tcpdump irqbalance
yum install -y --enablerepo=epel chrony jq htop nc
rpm -Uvh --force /tmp/bash-4.1.2-33.el6.1cloudpack.x86_64.rpm
rpm -ivh /tmp/ec2-net-utils-0.4-1.24.el6cloudpack.noarch.rpm
rpm -ivh /tmp/ec2-utils-0.4-1.24.el6cloudpack.noarch.rpm
chkconfig chronyd on
chkconfig irqbalance on
chkconfig sysstat on
chkconfig lvm2-monitor off

[ -f vmimport.ifcfg-lo ] && mv /etc/sysconfig/network-scripts/vmimport.ifcfg-lo /etc/sysconfig/network-scripts/ifcfg-lo
[ -f ifcfg-eth0.vmimport ] && rm /etc/sysconfig/network-scripts/ifcfg-eth0.vmimport
[ -f /etc/udev/rules.d/70-persistent-net.rules ] && rm /etc/udev/rules.d/70-persistent-net.rules
sed -i.bak 's:\(DRIVERS==\"?\*\",\):#\1:g' /lib/udev/rules.d/75-persistent-net-generator.rules

cat << EOT >> /etc/sysconfig/init
ulimit -n 524288
EOT

sed -i -e "s/^ZONE/#ZONE/g" -e "1i ZONE=\"Asia/Tokyo\"" /etc/sysconfig/clock
/usr/sbin/tzdata-update

cp /tmp/rpsxps /etc/init.d/ && chmod ugo+x /etc/init.d/rpsxps && chkconfig rpsxps on

cat << EOT >> /etc/sysctl.conf
# allow testing with buffers up to 64MB 
net.core.rmem_max = 67108864 
net.core.wmem_max = 67108864 
# increase Linux autotuning TCP buffer limit to 32MB
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
# increase the length of the processor input queue
net.core.netdev_max_backlog = 30000
# recommended default congestion control is htcp 
net.ipv4.tcp_congestion_control=htcp
# recommended for hosts with jumbo frames enabled
net.ipv4.tcp_mtu_probing=1

kernel.sem = 250 32000 100 128
fs.file-max = 6815744
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.wmem_default = 262144
fs.aio-max-nr = 1048576

vm.swappiness = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOT

cat << EOT >> /etc/security/limits.d/99-cloudpack.conf
* soft nofile 65536
* hard nofile 65536
EOT

cat << EOT >> /etc/profile.d/motd.sh
CURL_CMD="curl --max-time 2 --connect-timeout 2 -s"
echo "####"
echo -e "#### You have logged in to \e[1mlocalhost.localdomain\e[m as \e[1m\$(id -n -u)\e[m successfully."
InstanceID=\$( \${CURL_CMD} 169.254.169.254/latest/meta-data/instance-id)
if [ \$? -eq 0 ]; then
	echo -e "#### This server is running on \e[1m\e[33mAWS\e[m."
	echo "####   Instance ID:       \$( \${CURL_CMD} 169.254.169.254/latest/meta-data/instance-id)"
	echo "####   Instance Type:     \$( \${CURL_CMD} 169.254.169.254/latest/meta-data/instance-type)"
	echo "####   Availability Zone: \$( \${CURL_CMD} 169.254.169.254/latest/meta-data/placement/availability-zone)"
	echo "####   Private IP:        \$( \${CURL_CMD} 169.254.169.254/latest/meta-data/local-ipv4)"
	public_ip=\$( \${CURL_CMD} 169.254.169.254/latest/meta-data/public-ipv4 | head -n 1 | grep -e "^[^<]")
	echo "####   Public IP:         \$public_ip"
else
	echo "####   Private IP:        \$(/sbin/ip -f inet addr show | gawk '\$0 ~ /inet/ {print \$2}'| grep -v "127.0.0.1")"
fi
echo "####"
EOT

cat << EOT >> /etc/profile.d/bash_completion.sh
# history にコマンド実行時刻を記録する
HISTTIMEFORMAT='%Y-%m-%dT%T%z '
HISTSIZE=1000000
EOT
