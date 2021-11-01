#!/usr/bin/env bash

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
AMQ_CREDENTIAL=$(echo "QWRtaW4jMTIzNA==" | base64 -d)

write_container_id_in_pod_store (){

    val=`cat /proc/self/cgroup | grep ':name' | head -1 | cut -d '/' -f5 | cut -d '-' -f2 | cut -d '.' -f1`
    CID+="${val}"
    echo $CID > /opt/container/cid.txt
}

write_container_id_in_pod_store

_main () {
    if [ "$IS_ACTIVEMQ_MASTER_SLAVE" = "true" ]; then
        set_activemq_networkconnector
    fi
    set_jvm_args
    reset_admin_credentials
}

set_activemq_networkconnector() {
    networkUriString=$( get_url_based_on_replica_count );
    echo "Constructed network URI is ${networkUriString}";
        sed -i -e '/<\/persistenceAdapter>/a \
              \t\t<networkConnectors> \
              \t\t\t<networkConnector duplex="true" uri="masterslave:('${networkUriString}')"/> \
              \t\t</networkConnectors>' /usr/share/activemq/conf/activemq.xml
}

get_url_based_on_replica_count(){
    networkUri=$(a=0; while [[ $a -lt $ACTIVEMQ_REPLICA_COUNT ]]; do echo -n "tcp://activemq-${a}.activemq-broker-headless-service:61616",;a=`expr $a + 1`; done| sed 's/,$//');
    echo $networkUri;
}


set_jvm_args() {
    [[ $AMQ_JVM_ARGS && ${AMQ_JVM_ARGS-x} ]] && (echo "AMQ_JVM_ARGS Found";rewrite_env_file) \
       || (echo -e "${RED}AMQ_JVM_ARGS 'Not' Found. No change in JVM options. Proceed with OOTB settings.${NOCOLOR}")
}

rewrite_env_file() {
    echo
    echo -e "${GREEN}Configuring new JVM options [ $AMQ_JVM_ARGS ] for ActiveMQ Services${NOCOLOR}"
    echo
    line_txt_to_replace="ACTIVEMQ_OPTS_MEMORY="
    replacement_line="${line_txt_to_replace}\"${AMQ_JVM_ARGS}\""

    echo "Text to be added :: ${replacement_line}"
    ln=$(grep -nr "${line_txt_to_replace}"  $ACTIVEMQ_HOME/bin/env | cut -d : -f 1)

    echo "Found text at line no. -- $ln"

    #delete the line number containing the string for activemq mem. opts.
    sed -i -e '/ACTIVEMQ_OPTS_MEMORY=/ d' $ACTIVEMQ_HOME/bin/env

    #replace the new string for activemq mem. opts.
    sed -i "${ln}i ${replacement_line}" $ACTIVEMQ_HOME/bin/env

    echo
}

reset_admin_credentials () {
    echo
    echo -e "${GREEN}.....Resetting ActiveMQ Admin Password..... ${NOCOLOR}"
    echo

    # Changing admin password if provided
    if [[ ! -z "${AMQ_ADMIN_PASSWORD}" ]]; then
       AMQ_CREDENTIAL=${AMQ_ADMIN_PASSWORD}
    fi
        # Remove standard user from access web console
        sed -i "s/user: user, user//g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
        # Remove guest from accessing broker
        sed -i "s/guest.*//g" ${ACTIVEMQ_HOME}/conf/credentials.properties
         # Change admin password if set vie env variable
        sed -i "s/admin=.*/admin="${AMQ_CREDENTIAL}"/g" ${ACTIVEMQ_HOME}/conf/users.properties
        sed -i "s/admin.*/admin: "${AMQ_CREDENTIAL}", admin/g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
}

set_java_opts() {

    if [ ! -z "$AMQ_JVM_ARGS" ]; then
        heapMemoryArgs="$AMQ_JVM_ARGS"
    else
        heapMemoryArgs="-Xms64M -Xmx2G"
    fi

    JAVA_OPTS="$heapMemoryArgs -Dorg.apache.activemq.UseDedicatedTaskRunner=true -Djava.util.logging.config.file=logging.properties -Dcom.sun.management.jmxremote"
}

_main
echo
echo -e "${GREEN}....... Initiating ActiveMQ Services ....... ${NOCOLOR}"

set_java_opts
echo
echo "Starting ActiveMQ with Command: \"java $JAVA_OPTS -jar $ACTIVEMQ_HOME/bin/activemq.jar start\""
echo
exec $JAVA_HOME/bin/java $JAVA_OPTS -jar $ACTIVEMQ_HOME/bin/activemq.jar start
