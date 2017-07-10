#
# DCM4CHEE - Open source picture archive and communications server (PACS)
#
FROM debian:7
MAINTAINER AI Analysis, Inc <admin@aianalysis.com>

ENV java_version=6
ENV DCM4CHEE_HOME=/var/local/dcm4chee
ENV DCM_VER=2.18.1
ENV DCM_DIR=$DCM4CHEE_HOME/dcm4chee-$DCM_VER-psql 

# Load the stage folder, which contains the setup scripts.
#
RUN apt-get update
RUN apt-get -y upgrade

# Install dependencies
RUN apt-get install -y curl vim zip wget openjdk-$java_version-jdk
ENV PSQL_VER=9.1
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" > /etc/apt/sources.list.d/pgdg.list
#RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main $PSQL_VER" > /etc/apt/sources.list.d/pgdg.list
RUN gpg --keyserver keys.gnupg.net --recv-keys ACCC4CF8
RUN gpg --export --armor ACCC4CF8|apt-key add -
RUN apt-get update

RUN apt-get install postgresql-$PSQL_VER postgresql-client-$PSQL_VER postgresql-contrib-$PSQL_VER -y
USER postgres
ENV PG_HBA_CONF=/etc/postgresql/$PSQL_VER/main/pg_hba.conf
RUN sed -e '90d' -i $PG_HBA_CONF && sed -e '91d' -i $PG_HBA_CONF

RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/$PSQL_VER/main/pg_hba.conf
RUN echo "local all all trust" >> /etc/postgresql/$PSQL_VER/main/pg_hba.conf
RUN echo "host    all         all         127.0.0.1/32          trust"  >> /etc/postgresql/$PSQL_VER/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/$PSQL_VER/main/postgresql.conf

# Expose  PORT
EXPOSE 5432

USER root
# Make the dcm4chee home dir
RUN mkdir -p stage && mkdir -p $DCM4CHEE_HOME && cd $DCM4CHEE_HOME

# Download the binary package for DCM4CHEE
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4chee/$DCM_VER/dcm4chee-$DCM_VER-psql.zip > $DCM4CHEE_HOME/dcm4chee-$DCM_VER-psql.zip && unzip -q $DCM4CHEE_HOME/dcm4chee-$DCM_VER-psql.zip && rm $DCM4CHEE_HOME/dcm4chee-$DCM_VER-psql.zip && DCM_DIR=$DCM4CHEE_HOME/dcm4chee-$DCM_VER-psql 

# Download the binary package for JBoss
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip > $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && unzip -q $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && rm $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && JBOSS_DIR=$DCM4CHEE_HOME/jboss-4.2.3.GA

# Download the Audit Record Repository (ARR) package
#RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4chee-arr/3.0.12/dcm4chee-arr-3.0.12-psql.zip > $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-psql.zip && unzip -q $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-psql.zip && rm $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-psql.zip && ARR_DIR=$DCM4CHEE_HOME/dcm4chee-arr-3.0.12-psql

# Download toolkit
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4che2/2.0.29/dcm4che-2.0.29-bin.zip > $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip && unzip -q $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip && rm $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip

# Copy files from JBoss to dcm4chee
RUN cd $DCM4CHEE_HOME && $DCM_DIR/bin/install_jboss.sh jboss-4.2.3.GA > /dev/null

# Correct versions for ARR
#RUN sed -ri "s/VERS=3.0.11/VERS=3.0.12/" $DCM_DIR/bin/install_arr.sh && sed -ri "s/dcm4che-core-2.0.25/dcm4che-core-2.0.27/" $DCM_DIR/bin/install_arr.sh
# Copy files from the Audit Record Repository (ARR) to dcm4chee
#RUN cd $DCM4CHEE_HOME && $DCM_DIR/bin/install_arr.sh $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql > /dev/null

# Update environment variables
RUN echo "\
JAVA_HOME=/usr/lib/jvm/java-$java_version-openjdk-amd64\n\
PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
" > /etc/environment
RUN echo 'source /etc/environment' > ~/.bashrc

ADD stage stage
RUN chmod 755 stage/*.bash
RUN cd stage; ./setup.bash

CMD ["stage/start.bash"]
