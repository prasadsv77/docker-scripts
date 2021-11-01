Introduction:

This chart bootstraps an ActiveMQ  deployment on a Kubernetes cluster using the Helm package manager.


Installing the Chart:
To install the chart with the release name my-release:

$ helm install --name my-release activemq/

The command deploys ActiveMQ on the Kubernetes cluster in the default configuration.

Uninstalling the Chart:
To uninstall/delete the my-release deployment:

$ helm delete --purge my-release

The command removes all the Kubernetes components associated with the chart and deletes the release.
