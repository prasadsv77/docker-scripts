
Jaspersoft docker image creation. Build commands are below:
-------------------------------------------------------------------------------------------------------------------------

    docker build -t ca_ppm_jaspersoft_7.1.0_6.1.0.28 --build-arg JASPER_MAJOR_VERSION=7.1.0 --build-arg JASPER_JAAS_VERSION=6.1.0.28 .

    docker tag ca_ppm_jaspersoft_7.1.0_6.1.0.28 itc-dsdc.ca.com:5000/clarity/common/ca_ppm_jaspersoft_7.1.0_6.1.0.28:latest

    docker push itc-dsdc.ca.com:5000/clarity/common/ca_ppm_jaspersoft_7.1.0_6.1.0.28:latest

-------------------------------------------------------------------------------------------------------------------------

Run Jaspersoft container to install only Jaspersoft DB Schema:

    docker run -it -p 8081:8081 --env-file ./scripts/environment.properties ca_ppm_jaspersoft_7.1.0_6.1.0.28 "INSTALL_JSFT_DB"

Run Jaspersoft container to install only Jaspersoft Web App:

    docker run -it -p 8081:8081 --add-host=samsh06-docker:10.131.127.130 --env-file ./scripts/environment.properties ca_ppm_jaspersoft_7.1.0_6.1.0.28 "DEPLOY_JSFT_APP"

Run Jaspersoft container to install Jaspersoft DB Schema and Deploy Web App:

    docker run -it -p 8081:8081 --env-file ./scripts/environment.properties ca_ppm_jaspersoft_7.1.0_6.1.0.28 "INSTALL_JSFT_DB|DEPLOY_JSFT_APP"

-------------------------------------------------------------------------------------------------------------------------

Things to note:

* When running in Jaspersoft Server in cluster, we need JMS services to replicate cache among each node. For the purpose, we use ActiveMQ services for cache replication defined by ehcache.
* Start ActiveMQ container services and expose admin port (8161) and message port (61616).
* Start Jaspersoft Server container services on port 8081. Set the following environment variables - `JS_DEPLOYMENT_ENV_TYPE=multi-node` && ACTIVEMQ_PROVIDER_HOST_PORT=<hostname of activemq service>:61616
* This will start Jaspersoft Server container with cache replication enabled. But, sometimes docker container may not be able to resolve the host as docker services creates it own network bridge and host's firewall will block the same.
* Follow the steps below to rectify such issue:
    # Define a network bridge for docker on host machine.
      1. Open the file - /etc/docker/daemon.json .
      2. Add the network bridge definition as json - {"bip": "172.26.0.1/16"}, save the file and restart the docker services.
      3. Allow the host firewall to accept all the connection from above defined docker subnet - firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=172.26.0.1/16 accept' && firewall-cmd --reload


