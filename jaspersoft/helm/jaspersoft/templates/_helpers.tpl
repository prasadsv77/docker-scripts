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
