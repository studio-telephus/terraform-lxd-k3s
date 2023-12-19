#!/usr/bin/env bash
: "${RANDOM_STRING?}"
: "${CONTAINER_K3S_MYSQL_IP?}"
: "${MYSQL_K3S_USERNAME?}"
: "${MYSQL_K3S_PASSWORD?}"
: "${MYSQL_K3S_DATABASE?}"
: "${MYSQL_ROOT_PASSWORD?}"

# env > /tmp/env.out

apt-get install -y lsb-release openssl wget dirmngr netcat

## MySQL
wget -O /tmp/mysql-apt-config.deb https://repo.mysql.com/mysql-apt-config_0.8.26-1_all.deb

echo "mysql-apt-config mysql-apt-config/unsupported-platform select abort" | /usr/bin/debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-codename   select bullseye" | /usr/bin/debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-tools select" | /usr/bin/debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-distro select debian" | /usr/bin/debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.0" | /usr/bin/debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-product select Apply" | /usr/bin/debconf-set-selections

export DEBIAN_FRONTEND=noninteractive
dpkg -i /tmp/mysql-apt-config.deb

# TODO: The GPG signature issue https://github.com/apache/airflow/issues/36231
apt-get update --allow-insecure-repositories

apt-get update

debconf-set-selections <<< \
"mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"

debconf-set-selections <<< \
"mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"

debconf-set-selections <<< \
"mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"

export DEBIAN_FRONTEND=noninteractive
# TODO: remove GPG hotfix
apt-get install mysql-server -y --allow-unauthenticated

cat /etc/mysql/mysql.conf.d/default-auth-override.cnf

sleep 2
cp -pr /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.orig
sed 's/'127.0.0.1'/'0.0.0.0'/g' -i /etc/mysql/mysql.conf.d/mysqld.cnf

cat > /etc/mysql/mysql.conf.d/my-custom.cnf << EOF
[mysqld]
binlog_expire_logs_seconds = 86400
EOF

cat << EOF > /tmp/db-init.sql
CREATE USER '${MYSQL_K3S_USERNAME}'@'%' IDENTIFIED BY '${MYSQL_K3S_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_K3S_USERNAME}'@'%';
CREATE DATABASE ${MYSQL_K3S_DATABASE} CHARACTER SET utf8 COLLATE utf8_general_ci;
EOF

cat << EOF > /root/.mysql-root.cnf
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF

chmod 600 /root/.mysql-root.cnf

systemctl restart mysql
sleep 2
mysql --defaults-extra-file=/root/.mysql-root.cnf < /tmp/db-init.sql

rm /tmp/db-init.sql

### Test
nc -zv localhost 3306
mysql -h ${CONTAINER_K3S_MYSQL_IP} \
 -u${MYSQL_K3S_USERNAME} \
 -p${MYSQL_K3S_PASSWORD} \
 -e"quit"

echo "K3S MySQL database ready!"
