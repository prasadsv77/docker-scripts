{{- define "validate" -}}

{{- /* env variable deprecated
{{- $env := list "OP" "OD" -}}
{{- if not (has .Values.env $env) -}}
{{- fail ".Values.env is invalid environment value, allowed values are OP or OD" -}}
{{- end -}}
*/}}
{{- include "validatefn" (dict "path" "namespace" "values" .Values "regexKey" "true") -}}

{{- $pvenabled := list true false -}}
{{- if not (has .Values.pv.enabled $pvenabled) -}}
{{- fail ".Values.pv.enabled is invalid boolean, allowed values are true or false" -}}
{{- end -}}

{{- if (eq .Values.deploymentType "pipeline") -}}
{{- include "validatefn" (dict "path" "pv.custom.name" "values" .Values "regexKey" "true") -}}
{{- include "validatefn" (dict "path" "pv.keystore.name" "values" .Values "regexKey" "true") -}}
{{- end -}}

{{- if (eq .Values.deploymentType "standard") -}}
{{- include "validatefn" (dict "path" "pv.nfsServerName" "values" .Values) -}}
{{- include "validatefn" (dict "path" "pv.custom.name" "values" .Values "regexKey" "true") -}}
{{- include "validatefn" (dict "path" "pv.custom.storage" "values" .Values) -}}
{{- include "validatefn" (dict "path" "pv.custom.path" "values" .Values) -}}
{{- include "validatefn" (dict "path" "pv.keystore.name" "values" .Values "regexKey" "true") -}}
{{- include "validatefn" (dict "path" "pv.keystore.storage" "values" .Values) -}}
{{- include "validatefn" (dict "path" "pv.keystore.path" "values" .Values) -}}
{{- end -}}

{{- include "validatefn" (dict "path" "pvc.custom.name" "values" .Values "regexKey" "true") -}}
{{- include "validatefn" (dict "path" "pvc.keystore.name" "values" .Values "regexKey" "true") -}}
{{- include "validatefn" (dict "path" "pvc.custom.storage" "values" .Values) -}}
{{- include "validatefn" (dict "path" "pvc.keystore.storage" "values" .Values) -}}

{{- include "validatefn" (dict "path" "logstash.host" "values" .Values) -}}
{{- include "validatefn" (dict "path" "logstash.port" "values" .Values) -}}

{{- $routeenabled := list true false -}}
{{- if not (has .Values.route.enabled $routeenabled) -}}
{{- fail ".Values.route.enabled is invalid boolean, allowed values are true or false" -}}
{{- end -}}

{{- if (eq .Values.route.enabled true) -}}
{{- include "validatefn" (dict "path" "route.externalHostName" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.internalHostName" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.secure" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.tlsTermination" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.app.timeout" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.xog.timeout" "values" .Values) -}}
{{- include "validatefn" (dict "path" "route.admin.timeout" "values" .Values) -}}
{{- end -}}

{{- include "validatefn" (dict "path" "operationPod.resources.requests.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "operationPod.resources.requests.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "operationPod.resources.limits.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "operationPod.resources.limits.cpu" "values" .Values) -}}

{{- if .Values.adminDeployment.internalRoute -}}
{{- $internalroute := list true false }}
{{- if not (has .Values.adminDeployment.internalRoute $routeenabled) }}
{{- fail ".Values.adminDeployment.internalRoute is invalid boolean, allowed values are true or false" }}
{{- end }}
{{- end }}

{{- include "validatefn" (dict "path" "adminDeployment.strategy" "values" .Values) -}}
{{- include "validatefn" (dict "path" "adminDeployment.maxSurge" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.resources.requests.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "adminDeployment.resources.requests.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "adminDeployment.resources.limits.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "adminDeployment.resources.limits.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "adminDeployment.livenessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.livenessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.livenessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.livenessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.readinessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.readinessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.readinessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "adminDeployment.readinessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}

{{- include "validatefn" (dict "path" "appDeployment.strategy" "values" .Values) -}}
{{- include "validatefn" (dict "path" "appDeployment.maxSurge" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.resources.requests.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "appDeployment.resources.requests.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "appDeployment.resources.limits.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "appDeployment.resources.limits.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "appDeployment.livenessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.livenessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.livenessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.livenessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.readinessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.readinessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.readinessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "appDeployment.readinessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}

{{- include "validatefn" (dict "path" "bgDeployment.strategy" "values" .Values) -}}
{{- include "validatefn" (dict "path" "bgDeployment.maxSurge" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "bgDeployment.resources.requests.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "bgDeployment.resources.requests.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "bgDeployment.resources.limits.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "bgDeployment.resources.limits.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "bgDeployment.livenessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "bgDeployment.livenessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "bgDeployment.livenessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "bgDeployment.livenessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}

{{- $xogenable := list true false -}}
{{- if not (has .Values.xogDeployment.enable $xogenable) -}}
{{- fail ".Values.xogDeployment.enable is invalid boolean, allowed values are true or false" -}}
{{- end -}}

{{- if (eq .Values.xogDeployment.enable true) -}}
{{- include "validatefn" (dict "path" "xogDeployment.strategy" "values" .Values) -}}
{{- include "validatefn" (dict "path" "xogDeployment.maxSurge" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.resources.requests.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "xogDeployment.resources.requests.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "xogDeployment.resources.limits.memory" "values" .Values) -}}
{{- include "validatefn" (dict "path" "xogDeployment.resources.limits.cpu" "values" .Values) -}}
{{- include "validatefn" (dict "path" "xogDeployment.livenessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.livenessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.livenessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.livenessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.readinessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.readinessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.readinessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "xogDeployment.readinessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}
{{- end }}

{{- include "validatefn" (dict "path" "filebeatDeployment.terminationGracePeriodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "filebeatDeployment.uuid" "values" .Values) -}}
{{- include "validatefn" (dict "path" "filebeatDeployment.livenessProbe.failureThreshold" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "filebeatDeployment.livenessProbe.initialDelaySeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "filebeatDeployment.livenessProbe.periodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "filebeatDeployment.livenessProbe.timeoutSeconds" "values" .Values "numeric" "true") -}}

{{- include "validatefn" (dict "path" "clarity.image" "values" .Values) -}}
{{- include "validatefn" (dict "path" "clarity.tag" "values" .Values) -}}
{{- include "validatefn" (dict "path" "dependencyHandler.image" "values" .Values) -}}
{{- include "validatefn" (dict "path" "dependencyHandler.tag" "values" .Values) -}}
{{- include "validatefn" (dict "path" "configHandler.image" "values" .Values) -}}
{{- include "validatefn" (dict "path" "configHandler.tag" "values" .Values) -}}
{{- include "validatefn" (dict "path" "filebeat.image" "values" .Values) -}}
{{- include "validatefn" (dict "path" "filebeat.tag" "values" .Values) -}}

{{- include "validatefn" (dict "path" "terminationGracePeriodSeconds" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "imagePullPolicy" "values" .Values) -}}
{{- include "validatefn" (dict "path" "initContainerLifeSpan" "values" .Values "numeric" "true") -}}

{{- include "validatefn" (dict "path" "tokens.repeatability.clrtDbImportStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtDwhImportStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtDbLinkCreateStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtCskStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtApmStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtAglStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtItdStatusToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtJsftIntegrationToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtHdpIntegrationToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.repeatability.clrtSsoIntegrationToken" "values" .Values "numeric" "true") -}}

{{- include "validatefn" (dict "path" "tokens.restart.adminRestartToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.restart.appRestartToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.restart.bgRestartToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.restart.xogRestartToken" "values" .Values "numeric" "true") -}}
{{- include "validatefn" (dict "path" "tokens.restart.filebeatRestartToken" "values" .Values "numeric" "true") -}}

{{- if .Values.documentServer -}}
{{- if (eq .Values.documentServer.enableFileScan true) -}}
{{- include "validateKey" (dict "path" "clamdscan.tcpAddr" "values" .Values) -}}
{{- end }}
{{- end }}

{{- end }}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "clarity.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "clarity.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clarity.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "clarity.labels" -}}
app.kubernetes.io/name: {{ include "clarity.name" . }}
helm.sh/chart: {{ include "clarity.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Evaluates the path and if the path exists in values.yaml 
then assigns the value to container key
else assigns default value if provided.
*/}}

{{- define "evaluate" -}}
{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- if (eq $keyExists "true")  }}
{{- if .requiredQuote }}
{{- if  eq .requiredQuote "true" }}
{{ .containerKey | indent 4 -}}='{{- $valuesObj -}}'
{{- else }}
{{ .containerKey | indent 4 -}}={{- $valuesObj -}}
{{- end -}}
{{- else }}
{{ .containerKey | indent 4 -}}={{- $valuesObj -}}
{{- end -}}
{{- else }}
{{- if .defaultValue }}
{{ .containerKey | indent 4 -}}={{- .defaultValue -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Evaluates the path and if the path and its values exists in values.yaml
then assigns the value to container key
else remove it from secret.
*/}}
{{- define "evaluateSecret" -}}
{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- if (eq $keyExists "true")  }}
{{- if $valuesObj }}
{{- if .requiredQuote }}
{{- if  eq .requiredQuote "true" }}
{{ .secretKey | indent 2 -}}: '{{ $valuesObj -}}'
{{- else }}
{{ .secretKey | indent 2 -}}: {{ $valuesObj -}}
{{- end -}}
{{- else }}
{{ .secretKey | indent 2 -}}: {{ $valuesObj -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end  -}}

{{/*
validation function checks whether the key value is empty
if not empty, check the regular expression in their respective formts if required
*/}}
{{- define "validatefn" -}}
{{-  $valuesObj := .values -}}
{{-  $regexObj := .regexKey -}}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path -}}
{{- if and (hasKey $valuesObj $subPath) ($valuesObj ) -}}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first -}}
{{- else  -}}
{{- $keyExists = "false" }}
{{- end  -}}
{{- end  -}}


{{- if (eq $keyExists "true")  }}
{{- if not (empty $valuesObj) -}}
{{- if .numeric -}}
{{- if not (kindIs "float64" $valuesObj) -}}
{{- fail " value should only consists of numeric value" -}}
{{- end -}}
{{- end -}}
{{- if $regexObj -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $valuesObj) -}}
{{- fail " value should consists of alphanumeric characters, '-' and must start and end with an alphanumeric character" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- if .numeric -}}
{{- fail " value should not be empty and consists of numeric value only" -}}
{{- end -}}
{{- if $regexObj -}}
{{- fail " value should not be empty and consists of alphanumeric characters, '-' and must start and end with an alphanumeric character" -}}
{{- end -}}
{{- fail  "value should not be empty" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "defaultfn" -}}
{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- $type := typeOf $valuesObj }}
{{- if (eq $keyExists "true") }}
{{- if (eq "bool" $type) }}
{{ .containerKey | indent 14 -}}: '{{- $valuesObj -}}'
{{- else }}
{{- fail "allowed values are true/false" -}}'
{{- end -}}
{{- else }}
{{- if .defaultValue }}
{{ .containerKey | indent 14 -}}: '{{- .defaultValue -}}'
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "defaultfnforretentionPeriodInDays" -}}
{{- $retentionPeriodInDaysObj := .retentionPeriodInDays }}
{{- $defaultRetentionObj := .defaultRetention }}
{{- $typeretentionPeriodInDaysObj := typeOf $retentionPeriodInDaysObj }}
{{- $typedefaultRetentionObj := typeOf $defaultRetentionObj }}
{{- if (eq "float64" $typeretentionPeriodInDaysObj) }}
{{- $retentionPeriodInDaysObj -}}
{{- else }}
{{- if (eq "float64" $typedefaultRetentionObj) }}
{{- $defaultRetentionObj -}}
{{- else }}
{{- 30 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "ExceptionList" -}}
{{- $defaultRetention := .defaultRetentionPeriodInDays }}
{{- range .logFileExceptionList -}}
{{ .filename }}:{{- include "defaultfnforretentionPeriodInDays" (dict "retentionPeriodInDays" .retentionPeriodInDays "defaultRetention" $defaultRetention) }},
{{- end -}}
{{- end -}}

{{/*
Creates dummy status in route.
*/}}
{{- define "chart.helmRouteFix" -}}
status:
  ingress: []
{{- end -}}


{{- define "evaluateValue" -}}
{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- $defaultvalue := .defaultValue }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- if (eq $keyExists "true") }}
{{- $valuesObj -}}
{{- else }}
{{- $defaultvalue -}}
{{- end -}}
{{- end -}}


{{/*
appends to the name of operation pod
*/}}
{{- define "helm.version" -}}
{{- include "evaluateValue" (dict "path" "version.helm" "values" .Values "defaultValue" "v3") }}
{{- end -}}

{{/*
Evaluates the path and if the path exists in values.yaml
then assigns the value to container key
else assigns default value if provided.
*/}}
{{- define "evaluateConfProp" -}}
{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- if (eq $keyExists "true")  }}
{{- if not (kindIs "invalid" $valuesObj) -}}
{{- if .requiredQuote }}
{{- if  eq .requiredQuote "true" }}
{{ .containerKey | indent 4 }} '{{ $valuesObj -}}'
{{- else }}
{{ .containerKey | indent 4 }} {{ $valuesObj -}}
{{- end -}}
{{- else }}
{{ .containerKey | indent 4 }} {{ $valuesObj -}}
{{- end -}}
{{- else }}
{{- fail  "value should not be empty" -}}
{{- end -}}
{{- else }}
{{- if .defaultValue }}
{{ .containerKey | indent 4 }} {{ .defaultValue -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
validation function checks whether the key value is empty
if not empty, check the regular expression in their respective formts if required
*/}}
{{- define "validateKey" -}}
{{-  $valuesObj := .values -}}
{{-  $regexObj := .regexKey -}}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path -}}
{{- if and (hasKey $valuesObj $subPath) ($valuesObj ) -}}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first -}}
{{- else  -}}
{{- $keyExists = "false" }}
{{- end  -}}
{{- end  -}}
{{- if (eq $keyExists "false")  }}
{{- fail  "Key should be enabled. This is required field." -}}
{{- end -}}
{{- end -}}



{{/*
{{- include "podsection" (dict key "nodeSelector" path "operationPod.nodeSelector" "values" .Values "default" "nodeSelector" "indentation" "4") }}
*/}}

{{- define "podsection" -}}

{{-  $valuesObj := .values }}
{{-  $keyExists := "true" }}
{{- range $index, $subPath := split "." .path  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}

{{- if (eq $keyExists "false")  }}
{{-  $valuesObj = .values }}
{{-  $keyExists = "true" }}
{{- range $index1, $subPath := split "." .default  }}
{{- if (hasKey $valuesObj $subPath ) }}
{{- $valuesObj = pluck $subPath $valuesObj $valuesObj | first }}
{{- else }}
{{- $keyExists = "false" }}
{{- end  }}
{{- end -}}
{{- end -}}

{{- if (eq $keyExists "true")  }}
{{-  $subindent := add .indentation 2 | int }}
{{ .key | indent .indentation }}:
{{- with $valuesObj }}
{{- toYaml . | nindent $subindent }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
define filebeat input configurations
*/}}
{{- define "filebeat.input.configurations" -}}
{{- with .Values.filebeatDeployment.input.configurations -}}
{{- toYaml . | trim | nindent 6 }}
{{- end }}
{{- end -}}

{{/*
define filebeat configurations
*/}}
{{- define "filebeat.configurations" -}}
{{- with .Values.filebeatDeployment.configurations -}}
{{- toYaml . | trim | nindent 4 }}
{{- end }}
{{- end -}}