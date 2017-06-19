#
# DCM4CHEE - Open source picture archive and communications server (PACS)
#
FROM debian:8
#MAINTAINER AI Analysis, Inc <admin@aianalysis.com>

ENV java_version=8
ENV DCM4CHEE_HOME=/var/local/dcm4chee
ENV DCM_VER=2.18.1
ENV DCM_DIR=$DCM4CHEE_HOME/dcm4chee-$DCM_VER-mysql 

# Update OS
RUN apt-get update && apt-get -y upgrade

# Install Java & dependencies
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list 
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get update
RUN apt-get install -y oracle-java8-installer oracle-java8-set-default
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -q -y install mysql-server
RUN apt-get install -y curl vim zip

# Expose mysql PORT
EXPOSE 3306

# Make the dcm4chee home dir
RUN mkdir -p $DCM4CHEE_HOME && cd $DCM4CHEE_HOME

# Download the binary package for DCM4CHEE
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4chee/$DCM_VER/dcm4chee-$DCM_VER-mysql.zip > $DCM4CHEE_HOME/dcm4chee-$DCM_VER-mysql.zip && unzip -q $DCM4CHEE_HOME/dcm4chee-$DCM_VER-mysql.zip && rm $DCM4CHEE_HOME/dcm4chee-$DCM_VER-mysql.zip && DCM_DIR=$DCM4CHEE_HOME/dcm4chee-$DCM_VER-mysql 

# Download the binary package for JBoss
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip > $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && unzip -q $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && rm $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6.zip && JBOSS_DIR=$DCM4CHEE_HOME/jboss-4.2.3.GA

# Download the Audit Record Repository (ARR) package
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4chee-arr/3.0.12/dcm4chee-arr-3.0.12-mysql.zip > $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql.zip && unzip -q $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql.zip && rm $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql.zip && ARR_DIR=$DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql

# Download toolkit
RUN cd $DCM4CHEE_HOME && curl -G http://netcologne.dl.sourceforge.net/project/dcm4che/dcm4che2/2.0.29/dcm4che-2.0.29-bin.zip > $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip && unzip -q $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip && rm $DCM4CHEE_HOME/dcm4che-2.0.29-bin.zip

# Copy files from JBoss to dcm4chee
RUN cd $DCM4CHEE_HOME && $DCM_DIR/bin/install_jboss.sh jboss-4.2.3.GA > /dev/null

# Correct versions for ARR
RUN sed -ri "s/VERS=3.0.11/VERS=3.0.12/" $DCM_DIR/bin/install_arr.sh && sed -ri "s/dcm4che-core-2.0.25/dcm4che-core-2.0.27/" $DCM_DIR/bin/install_arr.sh
# Copy files from the Audit Record Repository (ARR) to dcm4chee
RUN cd $DCM4CHEE_HOME && $DCM_DIR/bin/install_arr.sh $DCM4CHEE_HOME/dcm4chee-arr-3.0.12-mysql > /dev/null

# Expose mysql
RUN sed -ri "s/bind-address\s+= 127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf 

RUN mkdir -p /stage 
ADD stage stage
RUN chmod 755 stage/*.bash; cd stage; ./setup.bash

CMD ["stage/start.bash"]
