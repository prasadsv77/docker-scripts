################################################# SELECT OS STARTS #####################################################

ARG BASE_IMAGE="docker-repo-path-to-java-tomcat-jsft-pas-image"
FROM  $BASE_IMAGE
MAINTAINER Junaid Ansari <junaid.ansari@broadcom.com>, Pradeep Immaddisetty <pradeepkumar.immadisetty@broadcom.com>, Shirish Samantaray <shirish.samantaray@broadcom.com>

#################################################### SELECT OS ENDS ####################################################



############################################# BUILD ARGUMENTS STARTS ###################################################

ARG SFTP_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG JASPER_MAJOR_VERSION=7.1.0
ARG JASPER_JAAS_VERSION=6.1.0.28
ARG JASPERSOFT_LOCATION=/opt/jaspersoft_installer
ARG JASPERSOFT_WEB_APP_NAME=reportservice
ARG JASPERSOFT_INSTALLER_BASE_NAME=ca_ppm_jaspersoft
ARG JASPERSOFT_INSTALLER_EXT=zip
ARG JASPERSOFT_INSTALLER_NAME=${JASPERSOFT_INSTALLER_BASE_NAME}_${JASPER_MAJOR_VERSION}_${JASPER_JAAS_VERSION}.${JASPERSOFT_INSTALLER_EXT}
ARG MASTER_PROPERTIES_FILE=default_master.properties
ARG MASTER_PROPERTIES=${JASPERSOFT_LOCATION}/buildomatic/${MASTER_PROPERTIES_FILE}
ARG QUARTZ_PROPERTIES=${CATALINA_HOME}/webapps/${JASPERSOFT_WEB_APP_NAME}/WEB-INF/js.quartz.properties
ARG JASPERSERVER_LICENSE=jasperserver.license
ARG SCRIPTS_HOME="/opt/devops-scripts"
ARG ANT_HOME=${JASPERSOFT_LOCATION}/apache-ant
ARG DEFAULT_ENTRYPOINT_ARGUMENT=DEPLOY_JSFT_APP
ARG BUILDER_BASE=builder_base
ARG TOMCAT_HOME=/opt/tomcat
ARG NON_ROOT_GROUP=1010
ARG NON_ROOT_USER=1010
ARG JASPERSOFT_HTTP_PORT=8081
ARG JASPERSOFT_LOG_DIR=/opt/logs
ARG JASPERSOFT_DUMPS_DIR=/opt/logs/dumps
ARG JASPERSOFT_DIR=/opt/jsft
ARG JSFT_CONFIG_DIR="${JASPERSOFT_DIR}/input/configs"
ARG CONTAINER_UTILITY_API_DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG CONTAINER_UTILITY_API=container_utility_api
ARG CONTAINER_UTILITY_API_ZIP=container_utility_api.zip
ARG CONTAINER_UTILITY_API_OUTPUT_PATH="/opt/${CONTAINER_UTILITY_API}/output"
ARG CONTAINER_INSTALLER_KS_DIR="${JASPERSOFT_DIR}/keystore/installer"
ARG CHROME_DOWNLOAD_URL
ARG LEGACY_KEYSTORE_FILES
############################################# BUILD ARGUMENTS ENDS #####################################################



############################################# DEVOPS SCRIPT COPY STARTS ################################################

USER root
COPY scripts resources "${SCRIPTS_HOME}"/

############################################# DEVOPS SCRIPT COPY STARTS ################################################

############################################# CONTAINER UTILITY API INSTALLATION STARTS #######################################
RUN if [ -z "${CONTAINER_UTILITY_API_DOWNLOAD_LOCATION}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify CONTAINER_UTILITY_API_DOWNLOAD_LOCATION\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && /usr/bin/mkdir -p "${SCRIPTS_HOME}/${CONTAINER_UTILITY_API}" "${CONTAINER_UTILITY_API_OUTPUT_PATH}" \
 && /usr/bin/curl -k "${CONTAINER_UTILITY_API_DOWNLOAD_LOCATION}" -o "/tmp/${CONTAINER_UTILITY_API_ZIP}" \
 && cd "/tmp" \
 && /usr/bin/echo "Extracting ${CONTAINER_UTILITY_API_ZIP} ..." \
 && /usr/bin/unzip -q ${CONTAINER_UTILITY_API_ZIP} -d "${SCRIPTS_HOME}/${CONTAINER_UTILITY_API}" \
 && /usr/bin/rm -rf "${CONTAINER_UTILITY_API_ZIP}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${SCRIPTS_HOME}/${CONTAINER_UTILITY_API} \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${SCRIPTS_HOME}/overlay \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} /opt/${CONTAINER_UTILITY_API} \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${CONTAINER_UTILITY_API_OUTPUT_PATH} \
 && /usr/bin/chmod -R 700 ${SCRIPTS_HOME}/${CONTAINER_UTILITY_API} \
 && /usr/bin/chmod -R 700 ${SCRIPTS_HOME}/overlay \
 && /usr/bin/chmod -R 700 /opt/${CONTAINER_UTILITY_API} \
 && /usr/bin/chmod -R 700 ${CONTAINER_UTILITY_API_OUTPUT_PATH} \
 && cd "/tmp" \
 && /usr/bin/echo "Installing Google Chrome ..." \
 && if [[ -z "${CHROME_DOWNLOAD_URL}" ]] ; then echo CHROME_DOWNLOAD_URL arg not provided ; else echo CHROME_DOWNLOAD_URL arg is provided && /usr/bin/yum -y localinstall "${CHROME_DOWNLOAD_URL}"; fi \
 && /usr/bin/rm -rf "/tmp"/* 

############################################# CONTAINER UTILITY API INSTALLATION ENDS #######################################


############################################# DIR & ENV VARIABLE CREATION STARTS #######################################


RUN /usr/bin/yum -y install fontconfig libfontconfig.so.1 \
  && /bin/echo jaspersoft_version="${JASPER_MAJOR_VERSION}_${JASPER_JAAS_VERSION}" \
  && /usr/bin/mkdir -p "${JASPERSOFT_LOCATION}" \
  && /usr/bin/mkdir -p "${SCRIPTS_HOME}" \
  && /usr/bin/mkdir -p "${JASPERSOFT_LOG_DIR}" \
  && /usr/bin/mkdir -p "${JASPERSOFT_DUMPS_DIR}" \
  && /usr/bin/mkdir -p "${CONTAINER_INSTALLER_KS_DIR}" \
  && /bin/mkdir -p "${JSFT_CONFIG_DIR}" \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${JASPERSOFT_LOCATION} \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${SCRIPTS_HOME} \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${JASPERSOFT_LOG_DIR} \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${JASPERSOFT_DIR} \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${CONTAINER_INSTALLER_KS_DIR} \
  && /usr/bin/touch /etc/timezone \
  && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "/etc/timezone" \
  && /usr/bin/chmod -R 700 "/etc/timezone" \
  && /usr/bin/chmod -R 777 ${CONTAINER_INSTALLER_KS_DIR}

############################################# DIR & ENV VARIABLE CREATION ENDS #########################################


############################################# INSTALLER DOWNLOAD & SETUP STARTS ########################################

USER ${NON_ROOT_USER}

WORKDIR /opt

RUN /bin/ls -ltr /tmp/ \
  && /usr/bin/curl -k "${SFTP_LOCATION}/${JASPERSOFT_INSTALLER_NAME}" -H "Expect:" -o "/tmp/${JASPERSOFT_INSTALLER_NAME}" \
  && /bin/unzip -q "/tmp/${JASPERSOFT_INSTALLER_NAME}" -d "${JASPERSOFT_LOCATION}" \
  && /bin/chmod -R u+rwx ${JASPERSOFT_LOCATION}/* \
  && /bin/chmod -R u+rwx ${JASPERSOFT_LOCATION}/buildomatic/* \
  && /bin/chmod -R u+rwx ${JASPERSOFT_LOCATION}/apache-ant/bin/* \
  && /bin/rm -rf /tmp/${JASPERSOFT_INSTALLER_NAME} \
  && /bin/chmod -R u+rwx ${SCRIPTS_HOME}/* \
  && /bin/chmod -R u+rwx ${JASPERSOFT_LOG_DIR} \
  && /bin/mv ${SCRIPTS_HOME}/keystore.init.properties ${JASPERSOFT_LOCATION}/buildomatic/ \
  && user_home=`eval echo ~$USER` \
  && /bin/mv ${JASPERSOFT_LOCATION}/${JASPERSERVER_LICENSE} $user_home \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/docs \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/eval-licenses \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/samples \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/scripts \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/exports/*-catalog-db2-* \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/exports/*-catalog-mysql-* \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/jboss7 \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/sql/db2 \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/sql/mysql \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/sql/FoodMartCreateData.zip \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/conf_source/db/db2 \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/conf_source/db/mysql \
  && /bin/rm -rf ${CATALINA_HOME}/webapps/* \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/sample_conf  ${JASPERSOFT_LOCATION}/buildomatic/tools \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/jdbc-dep ${JASPERSOFT_LOCATION}/buildomatic/install_resources/extra-tmp-file \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/extra-files \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/extra-jars/jacocoant.jar \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/install_resources/extra-jars/serializer-2.7.2.jar \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/bin/do-*.bat \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/buildomatic/bin/do-*.sh \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/*.txt \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/*.pdf \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/*.bat \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/*.sh \
  && cd ${TOMCAT_HOME}* \
  && mkdir -p ./webapps/${JASPERSOFT_WEB_APP_NAME} \
  && cd ${JASPERSOFT_LOCATION} \
  && unzip -o -q ./jasperserver-pro.war -d ${TOMCAT_HOME}/webapps/${JASPERSOFT_WEB_APP_NAME} \
  && /bin/echo jaspersoft_version=${JASPER_MAJOR_VERSION}_${JASPER_JAAS_VERSION} \
  && /bin/rm -rf ${JASPERSOFT_LOCATION}/jasperserver-pro.war \
  && /bin/rm -rf ${TOMCAT_HOME}/logs \
  && /bin/rm -rf ${TOMCAT_HOME}/webapps/${JASPERSOFT_WEB_APP_NAME}/WEB-INF/logs \
  && /bin/ln -sf ${JASPERSOFT_LOG_DIR} ${TOMCAT_HOME}/logs \
  && /bin/ln -sf ${JASPERSOFT_LOG_DIR} ${TOMCAT_HOME}/webapps/${JASPERSOFT_WEB_APP_NAME}/WEB-INF/logs \
  && if [[ -z "${LEGACY_KEYSTORE_FILES}" ]] ; then echo LEGACY_KEYSTORE_FILES arg not provided ; else echo LEGACY_KEYSTORE_FILES arg is provided && /usr/bin/curl -k "${LEGACY_KEYSTORE_FILES}" -o "${JASPERSOFT_DIR}/installer-ks-file.zip"; fi 
  

############################################# SETUP JSFT CLEAN INSTALLER END ###########################################

############################################# SETUP REQUIRED ENV VAR STARTS ###########################################
ENV JASPERSOFT_LOCATION=${JASPERSOFT_LOCATION} \
        ANT_HOME=${JASPERSOFT_LOCATION}/apache-ant \
        QUARTZ_PROPERTIES=${QUARTZ_PROPERTIES} \
        SCRIPTS_HOME=${SCRIPTS_HOME} \
        PATH=${ANT_HOME}/bin:$CATALINA_HOME/bin:$PATH \
        JSFT_CONFIG_DIR=${JSFT_CONFIG_DIR}

LABEL jaspersoft_version="${JASPER_MAJOR_VERSION}_${JASPER_JAAS_VERSION}"
############################################# SSETUP REQUIRED ENV VAR END ###########################################


############################################# DEFINING ENTRYPOINT STARTS ###############################################

WORKDIR $CATALINA_HOME

ENTRYPOINT ["/opt/devops-scripts/entrypoint.sh"]
CMD ["DEPLOY_JSFT_APP"]

############################################# DEFINING ENTRYPOINT ENDS #################################################
