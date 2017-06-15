#
# DCM4CHEE - Open source picture archive and communications server (PACS)
#
FROM ubuntu:14.04
MAINTAINER AI Analysis, Inc <admin@aianalysis.com>

# Load the stage folder, which contains the setup scripts.
#
RUN apt-get update
RUN apt-get -y upgrade

# Install dependencies
RUN apt-get install -y curl wget vim zip mysql-server openjdk-6-jdk

# Expose mysql PORT
EXPOSE 3306

ADD stage stage
RUN chmod 755 stage/*.bash
RUN cd stage; ./setup.bash

CMD ["stage/start.bash"]
