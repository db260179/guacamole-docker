#!/bin/bash
start_mysql(){
    /usr/bin/mysqld_safe --datadir=/config/databases --user=nobody > /dev/null 2>&1 &
    RET=1
    while [[ RET -ne 0 ]]; do
        mysql -uroot -e "status" > /dev/null 2>&1
        RET=$?
        sleep 1
    done
}

# If databases do not exist, create them
if [ -f /config/databases/guacamole/guacamole_user.ibd ]; then
  echo "Database exists."
else
  echo "Initializing Data Directory."
  /usr/bin/mysql_install_db --datadir=/config/databases --user=nobody >/dev/null 2>&1
  echo "Installation complete."
  start_mysql
  echo "Creating user and database."
  mysql -uroot -e "CREATE DATABASE guacamole"
  PW=$(cat /config/guacamole/guacamole.properties | grep -m 1 "mysql-password:\s" | sed 's/mysql-password:\s//')
  mysql -uroot -e "CREATE USER 'guacamole'@'localhost' IDENTIFIED BY '$PW'"
  echo "Database created. Granting access to 'guacamole' user for localhost."
  mysql -uroot -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole.* TO 'guacamole'@'localhost'"
  mysql -uroot -e "FLUSH PRIVILEGES"
  mysql -uroot guacamole < /root/001-create-schema.sql
  mysql -uroot guacamole < /root/002-create-admin-user.sql
  echo "Shutting down."
  mysqladmin -u root shutdown
  sleep 3
  echo "chown time"
  chown -R nobody:users /config/databases
  chmod -R 755 /config/databases
  sleep 3
  echo "Initialization complete."
fi

echo "Starting MariaDB..."
/usr/bin/mysqld_safe --skip-syslog --datadir='/config/databases' --user=nobody
