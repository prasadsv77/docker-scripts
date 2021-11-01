################################################# SELECT OS STARTS #####################################################
ARG BASE_IMAGE="docker-repo-path-to-standard-apline-golden-image"
FROM  $BASE_IMAGE
MAINTAINER Junaid Ansari <junaid.ansari@broadcom.com>, Pradeep Immaddisetty <pradeepkumar.immadisetty@broadcom.com>, Shirish Samantaray <shirish.samantaray@broadcom.com>

#################################################### SELECT OS ENDS ####################################################



############################################# BUILD ARGUMENTS STARTS ###################################################

#e.g. - Supported protocol, FTP, HTTP & SFTP. Base URL for the download - ftp://<username>:<password>@ftpserver
ARG DOWNLOAD_LOCATION=sftp://<user>:<passwd>@<host>:</home/defaut-path>
ARG DOWNLOAD_HOME_DIR=/pas/container-artifacts

ARG NON_ROOT_GROUP=1010
ARG NON_ROOT_USER=1010

ARG USER_DIRECTORY=/opt
ARG WORKING_DIRECTORY=${USER_DIRECTORY}/config-handler
ARG SCRIPTS_DIR=${USER_DIRECTORY}/config-scripts
ARG RESOURCES_DIR=${USER_DIRECTORY}/resources
ARG PPM_DIR=${USER_DIRECTORY}/ppm
ARG CONFIG_HANDLER_LOGS_DIR=${USER_DIRECTORY}/logs
ARG ORCHESTRATION_FOLDER=${USER_DIRECTORY}/orchestration
ARG ORCHESTRATION_CLIENT_FOLDER=${ORCHESTRATION_FOLDER}/client
ARG VALIDATION_CLIENT_FILE=clarity-configuration-handlers-15.7.0-SNAPSHOT-installer.zip
ARG VALIDATION_CLIENT_URL=${DOWNLOAD_LOCATION}${DOWNLOAD_HOME_DIR}/validation-client/${VALIDATION_CLIENT_FILE}
ARG ORCHESTRATION_CLIENT_PATH=custom/free-radicals-k8s-client
ARG ORCHESTRATION_CLIENT_ZIP_NAME=clarity_k8s-client.zip
ARG DEPENDENCY_CLIENT_URL=${SFTP_LOCATION}/${ORCHESTRATION_CLIENT_PATH}/${ORCHESTRATION_CLIENT_ZIP_NAME}

############################################# BUILD ARGUMENTS ENDS #####################################################


################################################# CREATE DIR STARTS ####################################################
#Create required directories
USER root

RUN apk add --no-cache tzdata

RUN /bin/rm -rf "/tmp"/* \
  && /bin/mkdir -p "${SCRIPTS_DIR}" \
  && /bin/mkdir -p "${WORKING_DIRECTORY}" \
  && /bin/mkdir -p "${RESOURCES_DIR}" \
  && /bin/mkdir -p "${PPM_DIR}" \
  && /bin/mkdir -p "${CONFIG_HANDLER_LOGS_DIR}" \
  && /bin/mkdir -p "${ORCHESTRATION_CLIENT_FOLDER}" \
  && /bin/mkdir "${PPM_DIR}/resource" \
  && echo "Config Client download URL - ${VALIDATION_CLIENT_URL}" \
  && /usr/bin/wget "${VALIDATION_CLIENT_URL}" -O "${WORKING_DIRECTORY}/${VALIDATION_CLIENT_FILE}" \
  && /usr/bin/unzip "${WORKING_DIRECTORY}/${VALIDATION_CLIENT_FILE}" -d "${WORKING_DIRECTORY}" \
  && /bin/rm -f "${WORKING_DIRECTORY}/${VALIDATION_CLIENT_FILE}" \
  && echo "Dependency Client download URL - ${DEPENDENCY_CLIENT_URL}" \
  && /usr/bin/wget "${DEPENDENCY_CLIENT_URL}" -O "${ORCHESTRATION_CLIENT_FOLDER}/${ORCHESTRATION_CLIENT_ZIP_NAME}" \
  && cd "${ORCHESTRATION_CLIENT_FOLDER}" \
  && /usr/bin/unzip -q "${ORCHESTRATION_CLIENT_FOLDER}/${ORCHESTRATION_CLIENT_ZIP_NAME}" \
  && /bin/rm -rf "${ORCHESTRATION_CLIENT_FOLDER}/${ORCHESTRATION_CLIENT_ZIP_NAME}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${PPM_DIR}/resource" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${SCRIPTS_DIR}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${WORKING_DIRECTORY}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${RESOURCES_DIR}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${PPM_DIR}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${CONFIG_HANDLER_LOGS_DIR}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${ORCHESTRATION_FOLDER}" \
  && /bin/chown -R ${NON_ROOT_GROUP}:${NON_ROOT_USER} "${ORCHESTRATION_CLIENT_FOLDER}" \
  && /bin/touch /etc/localtime \
  && /bin/cp /usr/share/zoneinfo/UTC /etc/localtime

USER ${NON_ROOT_USER}
RUN  /bin/chmod -R 700 "${SCRIPTS_DIR}" \
  && /bin/chmod -R 700 "${WORKING_DIRECTORY}" \
  && /bin/chmod -R 700 "${RESOURCES_DIR}" \
  && /bin/chmod -R 700 "${PPM_DIR}" \
  && /bin/chmod -R 700 "${CONFIG_HANDLER_LOGS_DIR}" \
  && /bin/chmod -R 700 "${ORCHESTRATION_CLIENT_FOLDER}" \
  && /bin/chmod -R 700 "${PPM_DIR}/resource"

################################################## CREATE DIR ENDS #####################################################



############################################### CONFIGURATIONS STARTS ###############################################

WORKDIR ${WORKING_DIRECTORY}

############################################### CONFIGURATIONS ENDS #################################################

ENV PPM_HOME="${PPM_DIR}"

COPY scripts "${SCRIPTS_DIR}"/

COPY resources "${RESOURCES_DIR}"/

#TODO Need to download this file from maven
COPY resources/messages_en.properties "${PPM_DIR}/resource"

WORKDIR ${WORKING_DIRECTORY}

ENTRYPOINT ["/bin/sh", "/opt/config-scripts/config-handler.sh"]

CMD ["clarity","validate","json"]