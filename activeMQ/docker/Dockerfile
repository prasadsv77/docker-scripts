################################################# SELECT OS STARTS #####################################################

ARG BASE_IMAGE="docker-repo-standard-centOS7.2-image"
FROM $BASE_IMAGE
MAINTAINER Junaid Ansari <junaid.ansari@broadcom.com>, Pradeep Immaddisetty <pradeepkumar.immadisetty@broadcom.com>, Shirish Samantaray <shirish.samantaray@broadcom.com>, Arijit Dey <arijit.dey@broadcom.com>

#################################################### SELECT OS ENDS ####################################################


############################################# BUILD ARGUMENTS STARTS ###################################################

ARG DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
#e.g. - sftp://builder:Niku#1234@ppmoseutil.ca.com:/home/builder/ppm
ARG JDK_DOWNLOAD_URL=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG JDK_INSTALLER_NAME=jdk-8u171-linux-x64.tar.gz
ARG JAVA_LOCATION=/usr/java
ARG JAVA_HOME=/usr/java/jdk
ARG ACTIVE_MQ_VERSION=5.12.1
ARG ACTIVE_MQ_INSTALLER_NAME="apache-activemq-${ACTIVE_MQ_VERSION}-bin.tar.gz"
ARG ACTIVEMQ_HOME="/usr/share/activemq"
ARG SCRIPTS_HOME="/opt/devops-scripts"
ARG HDP_CONTAINER_DIR="/opt/container"
ARG NON_ROOT_GROUP=1010
ARG NON_ROOT_USER=1010

############################################# BUILD ARGUMENTS ENDS   ###################################################



############################################# DEVOPS SCRIPT COPY STARTS ################################################

COPY scripts  "/tmp"

############################################# DEVOPS SCRIPT COPY STARTS ################################################



############################################# DIR & ENV VARIABLE CREATION STARTS #######################################

USER root

RUN /usr/bin/mkdir -p "${SCRIPTS_HOME}" \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${SCRIPTS_HOME} \
  && /bin/cp -f "/tmp"/entrypoint.sh "${SCRIPTS_HOME}"/entrypoint.sh \
  && /bin/cp -f "/tmp"/livenessReadiness.sh "${SCRIPTS_HOME}"/livenessReadiness.sh \
  && /usr/bin/chmod -R 777 "${SCRIPTS_HOME}" \
  && /bin/rm -rf "/tmp"/* \
  && /usr/bin/mkdir -p "${ACTIVEMQ_HOME}" \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${ACTIVEMQ_HOME}" \
  && /usr/bin/chmod -R 700 "${ACTIVEMQ_HOME}" \
  && /usr/bin/mkdir -p "${HDP_CONTAINER_DIR}" \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${HDP_CONTAINER_DIR}" \
  && /usr/bin/rm -rf "/tmp"/* \
  && /usr/bin/unlink /etc/localtime \
  && /usr/bin/touch /etc/localtime \
  && /usr/bin/cp /usr/share/zoneinfo/UTC /etc/localtime

############################################# DIR & ENV VARIABLE CREATION ENDS #########################################



############################################# ACTIVEMQ DOWNLOAD & SETUP STARTS #########################################

USER ${NON_ROOT_USER}
RUN /bin/echo  -e "\033[32mDownload and Setup ACTIVEMQ - ${DOWNLOAD_LOCATION}/${ACTIVE_MQ_INSTALLER_NAME} ......... \033[0m" \
  && /bin/echo \
  && /usr/bin/curl -k "${DOWNLOAD_LOCATION}/${ACTIVE_MQ_INSTALLER_NAME}" -H "Expect:" -o "/tmp/${ACTIVE_MQ_INSTALLER_NAME}" \
  && /bin/tar -zxvf "/tmp/${ACTIVE_MQ_INSTALLER_NAME}" --strip-components=2 -C "${ACTIVEMQ_HOME}" \
  && /bin/rm -rf "/tmp"/*

############################################# ACTIVEMQ DOWNLOAD & SETUP ENDS #########################################



################################################# ACTIVEMQ SERVICE STARTS ##############################################
# configure PATH variable
ENV JAVA_HOME=${JAVA_HOME} \
    ACTIVEMQ_HOME=${ACTIVEMQ_HOME} \
    HDP_CONTAINER_DIR=${HDP_CONTAINER_DIR} \
    PATH=${ACTIVEMQ_HOME}/bin:${JAVA_HOME}/bin:$PATH 

WORKDIR ${ACTIVEMQ_HOME}/bin

ENTRYPOINT ["/opt/devops-scripts/entrypoint.sh"]

########################################################################################################################
