Steps to deploy ActiveMQ in K8S

Step#1: Create Volumes and namespace

kubectl create -f activemq.yml

Pre-Requisite: Namespace jsft is expected before execution of yml.

Note: currently ActiveMQ service is exposing via NodePort on 30037. You can access the application with URL http://<master-ip>:30037/
