This Helm Chart can used to deploy the Clarity Application into the Kubernetes Cluster.

Usage:

1. If you want to deploy the application, go to the chart directory and run the following command.

     "helm install -n <Release_name> <path_of_the_chart>"

     Exp: helm install -n clarity ./clarity 

2. If you want to delete the application, go to the chart directory and run the following command.

     "helm del <Release_name> --purge"

     Exp: helm del clarity --purge

