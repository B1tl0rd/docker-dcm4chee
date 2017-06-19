#!/bin/sh
set -v

# Make the dcm4chee home dir
DCM_DIR=$DCM4CHEE_HOME/dcm4chee-2.18.1-mysql
JBOSS_DIR=$DCM4CHEE_HOME/jboss-4.2.3.GA
ARR_DIR=$DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql
java_version=8

# Install and set up MySQL
mysql_install_db
/usr/bin/mysqld_safe &
sleep 5s
# Create the 'pacsdb' and 'arrdb' databases, and 'pacs' and 'arr' DB users.
mysql -uroot < /stage/create_dcm4chee_databases.sql
# Load the 'pacsdb' database schema
mysql -upacs -ppacs pacsdb < $DCM_DIR/sql/create.mysql
# The ARR setup script needs to be patched
sed "s/type=/engine=/g" $ARR_DIR/sql/dcm4chee-arr-mysql.ddl > fixed.ddl
mv fixed.ddl $ARR_DIR/sql/dcm4chee-arr-mysql.ddl
# Load the 'arrdb' database schema
mysql -uarr -parr arrdb < $ARR_DIR/sql/dcm4chee-arr-mysql.ddl

# create a user to allow external clients (e.g. mySQLWorkbench) to connect
# remember to change the password
echo "CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';\n \
GRANT ALL PRIVILEGES ON *.* TO 'username'@'localhost' WITH GRANT OPTION;\n \
CREATE USER 'username'@'%' IDENTIFIED BY 'password'; \n\
GRANT ALL PRIVILEGES ON *.* TO 'username'@'%' WITH GRANT OPTION; \n\
FLUSH PRIVILEGES;\n \
quit \n" > init.sql
mysql -uroot < init.sql;

killall mysqld
sleep 5s

# Patch the JPEGImageEncoder issue for the WADO service
sed -e "s/value=\"com.sun.media.imageioimpl.plugins.jpeg.CLibJPEGImageWriter\"/value=\"com.sun.image.codec.jpeg.JPEGImageEncoder\"/g" < $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml > dcm4chee-wado-xmbean.xml
mv dcm4chee-wado-xmbean.xml $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml

# Update environment variables
echo "\
JAVA_HOME=/usr/lib/jvm/java-$java_version-oracle\n\
PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
" > /etc/environment
echo 'source /etc/environment' > ~/.bashrc
#source /etc/environment
