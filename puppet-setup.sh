cd /root
rpm -Uvh https://yum.puppet.com/puppet-tools-release-el-7.noarch.rpm
rpm -Uvh https://yum.puppet.com/puppet-release-el-7.noarch.rpm
yum install -y puppet-bolt
yum install -y pdk
curl -JLO "https://pm.puppet.com/cgi-bin/download-cgi?dist=el&rel=7&arch=x86_64&ver=latest"
tar xvzf puppet-enterprise-2019.5.0-el-7-x86_64.tar.gz
cd /root/puppet-enterprise-2019.5.0-el-7-x86_64
./puppet-enterprise-installer
