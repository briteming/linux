#!/bin/sh
# service mysqld stop; rm -rf /var/lib/mysql; rm -rf /etc/my.cnf; yum remove mysql-community-server mysql mysql-community-client mysql
# sed -i 's/^skip-grant-tables/#skip-grant-tables/' /etc/my.cnf
# yum install mysql-community-server  --enablerepo="mysql57-community"
# set global validate_password_policy=0;

# tpwd=$(grep "temporary password is" /var/log/mysqld.log |awk -F": " '{ print $2}')


. "/root/centos/fun.sh"

rpm -q mysql-community-server > /dev/null

if [ $? != 0 ]; then
	yum install mysql-community-server  --enablerepo="mysql57-community"
	if [ $? = 0 ]; then
		root_password=$(</dev/urandom tr -dc A-Za-z0-9 | head -c32)
		echo $root_password >> /root/centos/site.txt
		echo >> /root/centos/site.txt
		/root/centos/mysql.sh
		service mysqld start;
		\cp /etc/my.cnf /root
		red "mysql root密码 $root_password"

mysql -uroot << EOF
flush privileges;
update mysql.user set authentication_string=password('$root_password'), password_expired = 'N', password_last_changed = now() where user='root';
EOF

			sed -i "s/^pwd=.*/pwd=${root_password}/" "/root/centos/dber.sh"
			sed -i "s/^pwd=.*/pwd=${root_password}/" "/root/centos/addsite.sh"
			sed -i "s/-p123456/-p${root_password}/" "/root/centos/qps.sh"
			sed -i "s/^define('DBPW'.*/define('DBPW', '${root_password}');/" "/root/centos/expuser.php"
			ln -vsf /root/centos/dber.sh /sbin

			sed -i 's/^#validate_password_policy=0/validate_password_policy=0/' /etc/my.cnf
			sed -i 's/^skip-grant-tables/#skip-grant-tables/' /etc/my.cnf

			touch /var/log/mysqlslow.log
			chown mysql.mysql /var/log/mysqlslow.log

			rm -f /var/lock/subsys/mysqld
			service mysqld restart
			chkconfig mysqld on;
	fi
else
	green "mysql已安装"
fi
