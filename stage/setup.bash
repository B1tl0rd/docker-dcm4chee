#!/bin/sh
set -v

# Make the dcm4chee home dir
DCM_DIR=$DCM4CHEE_HOME/dcm4chee-2.18.1-psql
ARR_DIR=$DCM4CHEE_HOME/dcm4chee-arr-3.0.12-psql

export PGUSER=postgres
/etc/init.d/postgresql start
su postgres -c "createdb pacsdb"
su postgres -c "psql -q pacsdb -f $DCM_DIR/sql/create.psql"
su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE pacsdb TO $PGUSER;\""

# Patch the JPEGImageEncoder issue for the WADO service
sed -e "s/value=\"com.sun.media.imageioimpl.plugins.jpeg.CLibJPEGImageWriter\"/value=\"com.sun.image.codec.jpeg.JPEGImageEncoder\"/g" < $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml > dcm4chee-wado-xmbean.xml
mv dcm4chee-wado-xmbean.xml $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml

