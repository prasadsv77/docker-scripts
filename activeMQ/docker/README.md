
ActiveMQ docker image creation. Build commands are below:
-------------------------------------------------------------------------------------------------------------------------

    docker build -t activemq5.14.3 .

    docker tag activemq5.14.3 itc-dsdc.ca.com:5000/clarity/common/activemq5.14.3:latest

    docker push itc-dsdc.ca.com:5000/clarity/common/activemq5.14.3:latest

-------------------------------------------------------------------------------------------------------------------------

Run ActiveMQ container :

    docker run -d -p 61616:61616 -p 8161:8161 activemq5.14.3:latest

Access ActiveMQ admin webconsole :

    http://host-name:8161/



