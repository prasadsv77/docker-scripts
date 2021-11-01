Steps to deploy ActiveMQ in K8S

Step#1: Edit properties in deployment.properties
Step#2: use yml-generator.sh to generate the yml file by passing the deployment.properties as input along with the template
       - This will generate kubernetes Manifest file with required properties
Step#3: Deploy the yml file with below command
       kubectl apply -f activemq.yml

Note: currently ActiveMQ service is exposing via NodePort on 30086. You can access the application with URL http://<master-ip>:30086/

