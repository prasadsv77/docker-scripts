ansible-playbook playbook/kubernet_known_hosts.yaml > /tmp/ansible.log 

source host_cred

for server in `cat inventory | grep "^[^[;]" | grep -v ansible_ssh_common_args`;
 do 
    sshpass -p $host_password ssh-copy-id -i  ~/.ssh/id_rsa.pub $host_username@$server;
done
