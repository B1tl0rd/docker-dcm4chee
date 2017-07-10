#!/bin/bash
set -v

service postgresql start
/var/local/dcm4chee/dcm4chee-2.18.1-psql/bin/run.sh
