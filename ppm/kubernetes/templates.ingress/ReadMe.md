Below steps will describe the deployment of PPM in Kubernetes

Step#1: Edit properties in deployment-.properties Step#2: use yml-generator.sh to generate the yml file by passing the deployment-.properties as input along with the template - This will generate kubernetes Manifest file with required properties

#Convert each template file using to Kubernetes Manifest file by using the below commands,

/generator/ym-generator.sh config-<vendor>.yml.template deployment-<vendor>.properties
/generator/ym-generator.sh clarity.yml.template deployment-<vendor>.properties
/generator/ym-generator.sh filebeat.yml.template deployment-<vendor>.properties

Above commands will generate the Kubernetes Manifest files with names config-<vendor>.yml, clarity.yml and filebeat.yml

Step#3: Deploy YML files kubectl apply -f config-.yml kubectl apply -f clarity.yml kubectl apply -f filebeat.yml