{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "jaspersoft.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jaspersoft.fullname" -}}
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
{{- define "jaspersoft.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "jaspersoft.labels" -}}
app.kubernetes.io/name: {{ include "jaspersoft.name" . }}
helm.sh/chart: {{ include "jaspersoft.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
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
{{ .containerKey | indent .indentValue -}}: '{{- $valuesObj -}}'
{{- else }}
{{- fail "allowed values are true/false" -}}'
{{- end -}}
{{- else }}
{{- if .defaultValue }}
{{ .containerKey | indent .indentValue -}}: '{{- .defaultValue -}}'
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
This will help to introduce sections dynamically in deployment definitions
for e.g.
nodeSelector:
  app: engg
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
Set APP  protocol
*/}}
{{- define "set.app.ingress.protocol" -}}
{{- if .Values.platform -}}
    {{- if eq .Values.platform "gke" -}}
    {{- if .Values.ingress.app.sslEnable -}}
        {{- print "https://" | trunc 63 -}}
    {{- else -}}
        {{- print "http://" | trunc 63 -}}
    {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Set Infra  protocol
*/}}
{{- define "set.infra.ingress.protocol" -}}
{{- if .Values.platform -}}
    {{- if eq .Values.platform "gke" -}}
    {{- if .Values.ingress.infra.sslEnable -}}
        {{- print "https://" | trunc 63 -}}
    {{- else -}}
        {{- print "http://" | trunc 63 -}}
    {{- end -}}
    {{- end -}}
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