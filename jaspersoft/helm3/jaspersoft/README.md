This Helm Chart can  be used to deploy the Jaspersoft Application into the Kubernetes Cluster.

Usage:

1. If you want to deploy the application, go to the chart directory and run the following command.

     "helm install -n <Release_name> ./jaspersoft"

     Exp: helm install -n jaspersoft ./jaspersoft 

2. If you want to delete the application, go to the chart directory and run the following command.

     "helm del <Release_name> --purge"

     Exp: helm del jaspersoft --purge

