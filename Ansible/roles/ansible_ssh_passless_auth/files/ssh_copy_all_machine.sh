for server in `cat inventory`;  
do  
    sshpass -p "admin1" ssh-copy-id -i ~/.ssh/id_rsa.pub root@$server  
done
