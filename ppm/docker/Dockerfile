################################################# SELECT OS STARTS #####################################################

ARG BASE_IMAGE=<jFrog-host>:5000/clarity/common/jdk1.8.171_tomcat8.5.30:latest
FROM  $BASE_IMAGE
MAINTAINER Junaid Ansari <junaid.ansari@broadcom.com>, Pradeep Immaddisetty <pradeepkumar.immadisetty@broadcom.com>, Shirish Samantaray <shirish.samantaray@broadcom.com>

#################################################### SELECT OS ENDS ####################################################

############################################# BUILD ARGUMENTS STARTS ###################################################
ARG PPM_DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG PPM_HOME="/opt/ppm"
ARG POSTGRES_HOME="/opt/db"
ARG PPM_SHARE="/fs0/clarity1/share"
ARG PPM_HOME_SCRIPTS="/opt/devops-scripts"
ARG ADMIN_FOLDER="${PPM_HOME}/admin-content"
ARG CAPA_ZIP="/CAPA/capa_v15.2_12.1.01.1.zip"
ARG PGSQL_DOWNLOAD_LOCATION="http://isl-dsdc.ca.com/artifactory/maven-integration-local/com/ca/ppm/postgresql-10.10-2-linux-x64-binaries.tar.gz"
ARG CHECKINSTALL_DOWNLOAD_LOCATION=""
ARG POSTGRES_TAR_FILE="postgresql.tar.gz"
ARG CAPA_DOWNLOAD_LOCATION
ARG PPM_ZIP
ARG PPM_VERSION
ARG PPM_INSTALLER
ARG CLARITY_RELEASE
ARG TPJ_DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG THIRDPARTY_JAR="thirdparty.libs.${CLARITY_RELEASE}.jar"
ARG CHECKINSTALL_JAR=""
ARG CHECKINSTALL_HOME="/opt/checkinstall"
ARG TOMCAT_LOCATION="/opt/tomcat"
ARG NON_ROOT_GROUP=1010
ARG NON_ROOT_USER=1010
ARG CONTAINER_UTILITY_API="container_utility_api"
ARG CONTAINER_UTILITY_API_DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG CONTAINER_UTILITY_API_ZIP=container_utility_api.zip
ARG CONTAINER_UTILITY_API_OUTPUT_PATH="/opt/${CONTAINER_UTILITY_API}/output"

ARG CLAMAV_DOWNLOAD_LOCATION=http://clrt-i0106.dhcp.broadcom.net:8888/clamav/clamav-0.102.4.tar.gz
ARG HOME_DIR="/home/default"
ARG CLAMAV_HOME="${HOME_DIR}/clamav"
ARG CLAMD_DAEMON_CMD=${CLAMAV_HOME}/sbin/clamd
ARG FRESH_CLAM_CMD=${CLAMAV_HOME}/bin/freshclam
ARG LOG_DIR=${CLAMAV_HOME}/logs
ARG DB_DIR=${CLAMAV_HOME}/anti-virus-database/data
ARG CONF_DIR=${CLAMAV_HOME}/configs
ARG SCRIPT_DIR=${CLAMAV_HOME}/scripts
ARG NON_ROOT_GROUP=1010
ARG NON_ROOT_USER=1010
############################################# BUILD ARGUMENTS ENDS ###################################################

############################################# DIR & ENV VARIABLE CREATION STARTS #######################################
USER root

RUN /usr/bin/rm -rf "/tmp"/* \
 && /usr/bin/mkdir -p "${PPM_HOME}" \
 && /usr/bin/mkdir -p "${POSTGRES_HOME}" \
 && /usr/bin/mkdir -p "${PPM_SHARE}" \
 && /usr/bin/mkdir -p "${PPM_HOME_SCRIPTS}" \
 && /usr/bin/mkdir -p "${PPM_HOME}/.setup" \
 && /usr/bin/mkdir -p "${CHECKINSTALL_HOME}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_SHARE}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${PPM_HOME_SCRIPTS} \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${CHECKINSTALL_HOME} \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup" \
 && /usr/bin/touch /etc/timezone \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "/etc/timezone" \
 && /usr/bin/chmod -R 700 "/etc/timezone" \
 && yum install -y compat-openssl10 nss atk at-spi2-atk cups-libs libdrm libXcomposite libXdamage libXrandr libgbm pango alsa-lib libxshmfence libX11-xcb \
 && yum clean all \
 && /usr/bin/rm -rf /var/cache/yum \
 && /usr/bin/echo "/home/default/clamav/lib64" >> /etc/ld.so.conf \
 && /usr/bin/ln -s /usr/lib64/libjson-c.so.4.0.0 /usr/lib64/libjson-c.so.2 \
 && /sbin/ldconfig -v \
 && /usr/bin/mkdir -p "${CLAMAV_HOME}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${CLAMAV_HOME}"


ENV PPM_HOME="${PPM_HOME}" \
    NIKU_HOME="${PPM_HOME}" \
    PPM_HOME_SCRIPTS="${PPM_HOME_SCRIPTS}" \
    CHECKINSTALL_HOME="${CHECKINSTALL_HOME}" \
    PATH="${PATH}:${PPM_HOME}/bin" \
    CLARITY_RELEASE="${CLARITY_RELEASE}"

# @todo - add java and tomcat version to label metadata
LABEL ppm_version="${PPM_VERSION}" \
      ppm_installer="${PPM_INSTALLER}"
############################################# DIR & ENV VARIABLE CREATION ENDS #######################################

############################################# CONTAINER UTILITY API INSTALLATION STARTS #######################################
RUN if [ -z "${CONTAINER_UTILITY_API_DOWNLOAD_LOCATION}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify CONTAINER_UTILITY_API_DOWNLOAD_LOCATION\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && /usr/bin/mkdir -p "${PPM_HOME_SCRIPTS}/${CONTAINER_UTILITY_API}" "${CONTAINER_UTILITY_API_OUTPUT_PATH}" \
 && /usr/bin/curl -k "${CONTAINER_UTILITY_API_DOWNLOAD_LOCATION}" -o "/tmp/${CONTAINER_UTILITY_API_ZIP}" \
 && cd "/tmp" \
 && /usr/bin/echo "Extracting ${CONTAINER_UTILITY_API_ZIP} ..." \
 && /usr/bin/unzip -q ${CONTAINER_UTILITY_API_ZIP} -d "${PPM_HOME_SCRIPTS}/${CONTAINER_UTILITY_API}" \
 && /usr/bin/rm -rf "${CONTAINER_UTILITY_API_ZIP}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME_SCRIPTS}/${CONTAINER_UTILITY_API}" \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} /opt/${CONTAINER_UTILITY_API} \
 && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${CONTAINER_UTILITY_API_OUTPUT_PATH} \
 && /usr/bin/chmod -R 700 ${PPM_HOME_SCRIPTS}/${CONTAINER_UTILITY_API} \
 && /usr/bin/chmod -R 700 /opt/${CONTAINER_UTILITY_API} \
 && /usr/bin/chmod -R 700 ${CONTAINER_UTILITY_API_OUTPUT_PATH}
############################################# CONTAINER UTILITY API INSTALLATION ENDS #######################################

############################################# PPM INSTALLATION STARTS #######################################
USER ${NON_ROOT_USER}

# PPM and thirdparty jars
RUN if [ -z "${PPM_INSTALLER}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify PPM_INSTALLER\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && if [ -z "${THIRDPARTY_JAR}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify THIRDPARTY_JAR\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && ppm_version="$( /usr/bin/echo "${PPM_INSTALLER}" | /usr/bin/sed "s|saas\.clarity\.\(.*\)\.zip|\1|" )" \
 && ppm_major_version="$( /usr/bin/echo "${ppm_version}" | /usr/bin/sed "s|\([0-9]*\.[0-9]*\.[0-9]*\)\..*|\1|" )" \
 && thirdparty_jar_version=="$( /usr/bin/echo "${THIRDPARTY_JAR}" | /usr/bin/sed "s|thirdparty\.libs\.\(.*\)\.jar|\1|" )" \
 && /usr/bin/echo "..........TP:${thirdparty_jar_version}... PPM:${ppm_major_version}..." \
 && if [ ${ppm_major_version} = ${thirdparty_jar_version} ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: THIRDPARTY_JAR and PPM_INSTALLER should be in same version \e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && /usr/bin/echo "Attempting to download ${PPM_DOWNLOAD_LOCATION}/ and ${TPJ_DOWNLOAD_LOCATION} ..." \
 && /usr/bin/curl -k "${PPM_DOWNLOAD_LOCATION}" -o "/tmp/${PPM_INSTALLER}" \
 && /usr/bin/curl -k "${TPJ_DOWNLOAD_LOCATION}/${THIRDPARTY_JAR}" -o "/tmp/${THIRDPARTY_JAR}" \
 && cd "/tmp" \
 && /usr/bin/echo "Extracting ${PPM_INSTALLER} and ${THIRDPARTY_JAR} ..." \
 && /usr/bin/unzip -q "${PPM_INSTALLER}" "runtime"/* \
 && /usr/bin/mv "runtime"/* "runtime"/.[0-9a-zA-Z]* "${PPM_HOME}" \
 && if [[ `unzip -Z1 "${PPM_INSTALLER}" | grep patch.properties` ]]; then \
       /usr/bin/echo \
    && /usr/bin/unzip -q "${PPM_INSTALLER}" "patch.properties" \
    && /usr/bin/mv "patch.properties" "${PPM_HOME}/.setup/" \
   ; fi \
 && /usr/bin/unzip -qjo "${THIRDPARTY_JAR}" "${ppm_major_version}"/* -d "${PPM_HOME}/lib" \
 && /usr/bin/rm -rf "${PPM_INSTALLER}" "${THIRDPARTY_JAR}" \
 && /usr/bin/rm -rf ${PPM_HOME}/database/backups/*oracle* ${PPM_HOME}/database/backups/*mssql* \
 && cd "${PPM_HOME}" \
 && /usr/bin/mkdir -p "${TOMCAT_LOCATION}/shared/lib" \
 && if [ "$( expr "${ppm_major_version%.*}" \> "15.1" )" -eq "1" ]; then \
      if [ -f "lib/bc-fips.jar" ]; then \
        /usr/bin/cp "lib/bc-fips.jar" "${TOMCAT_LOCATION}/shared/lib" \
    ; fi \
  ; else \
      if /usr/bin/ls "lib"/*crypto*.jar > /dev/null 2>&1 ; then \
        /usr/bin/cp "lib"/*crypto*.jar "${TOMCAT_LOCATION}/shared/lib" \
    ; fi \
   && if /usr/bin/ls "lib"/*FIPS*.jar > /dev/null 2>&1 ; then \
        /usr/bin/cp "lib"/*FIPS*.jar "${TOMCAT_LOCATION}/shared/lib" \
    ; fi \
  ; fi \
 && /usr/bin/mkdir -p "logs" "config" "customconfig" "files/filestore" "files/searchIndex" "${ADMIN_FOLDER}" \
 && /usr/bin/echo "Setting attributes and permissions" \
 && cd "${PPM_HOME}/bin" \
 && /usr/bin/chmod u+rwx "admin" "antRun" "dbpatch" "gel" "service" "serviceant" "xog" \
 && /usr/bin/echo "Staging configuration files" \
 && /usr/bin/chmod -R u+rwx  "${PPM_HOME}/.setup" \
 && /usr/bin/find "${PPM_HOME}/.setup/templates/config/" -name "*.properties" -exec cp '{}' ${PPM_HOME}/config \; \
 && /usr/bin/find "${PPM_HOME}/.setup/templates/config/" -name "*.xml" -exec cp '{}' ${PPM_HOME}/config \; \
 && /usr/bin/rm -rf "${PPM_HOME}/config"/properties.xml && /usr/bin/rm -rf "${PPM_HOME}/config"/logger.xml \
 && /usr/bin/rm -rf "${PPM_HOME}/config"/components.xml \
 && /usr/bin/rm -rf "${PPM_HOME}"/playwright/**/chrome-win

############################################# PPM INSTALLATION ENDS #######################################

############################################# CAPA INSTALLATION STARTS #######################################
# CAPA
RUN if [ -z "${CAPA_ZIP}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify CAPA_ZIP\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && capa_zip="$( /usr/bin/basename "${CAPA_DOWNLOAD_LOCATION}" )" \
 && /usr/bin/echo "Attempting to download ${CAPA_DOWNLOAD_LOCATION} ..." \
 && /usr/bin/curl -k "${CAPA_DOWNLOAD_LOCATION}" -o "/tmp/${capa_zip}" \
 && cd "/tmp" \
 && /usr/bin/echo "Extracting ${capa_zip} ..." \
 && /usr/bin/unzip -q "${capa_zip}"  -d "${PPM_HOME}/webroot/" \
 && mv "${PPM_HOME}"/webroot/capa_v* "${PPM_HOME}/webroot/capa" \
 && /usr/bin/rm -rf "${capa_zip}" "/tmp"/*

############################################# CAPA INSTALLATION ENDS #######################################

############################################# CHCKINSTALL SETUP STARTS #######################################
# CHCKINSTALL
RUN if [ -z "${CHECKINSTALL_JAR}" ]; then \
      /usr/bin/echo \
   && /usr/bin/echo -e "\e[31mERROR: must specify CHECKINSTALL_JAR\e[0m" \
   && /usr/bin/echo \
   && exit 1 \
  ; fi \
 && /usr/bin/echo "Attempting to download ${CHECKINSTALL_DOWNLOAD_LOCATION} ..." \
 && /usr/bin/curl -k "${CHECKINSTALL_DOWNLOAD_LOCATION}" -o "/tmp/${CHECKINSTALL_JAR}" \
 && cd "/tmp" \
 && /usr/bin/echo "Extracting ${CHECKINSTALL_JAR} ..." \
 && /usr/bin/unzip -q "${CHECKINSTALL_JAR}" -d "${CHECKINSTALL_HOME}" \
 && /usr/bin/rm -rf "${CHECKINSTALL_JAR}" "/tmp"/*

############################################# CHCKINSTALL SETUP ENDS #######################################

############################################# CLAMAV SETUP STARTS #######################################
RUN /usr/bin/curl -k "${CLAMAV_DOWNLOAD_LOCATION}" -o "/tmp/clamav.tar.gz" \
    && cd "/tmp" \
    && tar -xzvf "clamav.tar.gz" --directory "/tmp" \
    && /usr/bin/mv clamav-* clamav \
    && /usr/bin/cp -rf /tmp/clamav/* "${CLAMAV_HOME}" \
    && cd "${CLAMAV_HOME}" \
    && /usr/bin/mkdir -pv "${LOG_DIR}" \
    && /usr/bin/mkdir -pv "${DB_DIR}" \
    && /usr/bin/mkdir -pv "${CONF_DIR}" \
    && /usr/bin/mkdir -pv "${SCRIPT_DIR}" \
    && /usr/bin/chmod -R 777 "${SCRIPT_DIR}" \
    && /usr/bin/chmod -R 777 "${DB_DIR}" \
    && /usr/bin/chmod -R 777 "${CONF_DIR}" \
    && /usr/bin/mkdir -pv /home/default/clamdscan-conf \
    && /usr/bin/rm -rf /tmp/*


############################################# CLAMAV SETUP ENDS #######################################

############################################# DEVOPS SCRIPTS & UTILITY COPY STARTS ##############################
USER root

COPY  .passwd hosts.xml "${PPM_HOME}/config/"
COPY  cd.xml patch.xml cd.macros.xml upgrade.xml cd.common.xml cd.checkinstall.xml "${PPM_HOME}/.setup/scripts/"
COPY  scripts "${PPM_HOME_SCRIPTS}"

RUN /usr/bin/echo "Attempting to download ${PGSQL_DOWNLOAD_LOCATION} ..." \
   && cd "/tmp" \
   && /usr/bin/curl -k "${PGSQL_DOWNLOAD_LOCATION}" -o "${POSTGRES_TAR_FILE}" \
   && /usr/bin/tar -xf "${POSTGRES_TAR_FILE}" \
   && /usr/bin/mv pgsql/bin pgsql/lib ${POSTGRES_HOME} \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/config/.passwd" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/config/hosts.xml" \
   && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME_SCRIPTS}" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/cd.xml" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/patch.xml" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/cd.macros.xml" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/cd.checkinstall.xml" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/upgrade.xml" \
   && /usr/bin/chown ${NON_ROOT_USER}:${NON_ROOT_GROUP} "${PPM_HOME}/.setup/scripts/cd.common.xml" \
   && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${POSTGRES_HOME} \
   && /usr/bin/chmod -R 700 "${PPM_HOME}" \
   && /usr/bin/chmod -R 777 "${PPM_SHARE}" \
   && /usr/bin/chmod -R 700 "${PPM_HOME_SCRIPTS}" \
   && /usr/bin/chmod -R 700 "${CHECKINSTALL_HOME}" \
   && /usr/bin/chmod -R 700 "${POSTGRES_HOME}" \
   && /usr/bin/chmod -R 777 "${ADMIN_FOLDER}" \
   && /usr/bin/rm -rf "/tmp"/* \
   && /usr/bin/chown -Rv ${NON_ROOT_USER}:${NON_ROOT_GROUP} ${CLAMAV_HOME} \
   && /usr/bin/chmod -R 700 "${CLAMAV_HOME}"


############################################# DEVOPS SCRIPTS & UTILITY COPY ENDS ##################################

#HEALTHCHECK --interval=2m30s --timeout=1m30s --retries=2 \
#   CMD ${PPM_HOME_SCRIPTS}/healthcheck/bghealthcheck.sh || exit 1

USER ${NON_ROOT_USER}
WORKDIR "${PPM_HOME}"

ENTRYPOINT ["/opt/devops-scripts/start-services.sh"]
CMD ["app"]
