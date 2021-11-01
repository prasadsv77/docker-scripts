#!/bin/bash

ColorOn=$'\e[0m'
BWhite='\e[1;37m'
echo -e "===================================================================================================================================================\n"
source host_cred
echo -e " This script is using below credential of all the hosts to start the cluster setup, If you want to change the creditial press ctrl+c and edit 'host_cred' file \n" 
echo "username:"$host_username
echo "password:"$host_password
sleep 5
echo "==================================================================================================================================================="
echo " Adding indivisual hosts details (ECDSA) into know_hosts file , it will take few seconds.... "
ansible-playbook playbook/kubernet_known_hosts.yaml > /tmp/ansi_logs
echo "==================================================================================================================================================="
echo " Copy ansible machine public ssh key to all host authorization.key to start password-less ssh connection"
echo "==================================================================================================================================================="
source host_cred
for server in `cat inventory | grep "^[^[;]" | grep -v ansible_ssh_common_args`;  
 do 
    echo "sshpass -p $host_password ssh-copy-id -i  ~/.ssh/id_rsa.pub $host_username@$server;"
	sshpass -p $host_password ssh-copy-id -i  ~/.ssh/id_rsa.pub $host_username@$server;
done
echo "==================================================================================================================================================="
echo "============================ finished ansible environment setup. Starting the main palybook to bootstarp kubernet cluster=========================="
ansible-playbook kubernet_cluster_setup.yaml
