{{- define "testapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testapp.fullname" -}}
{{- printf "%s-%s" (include "testapp.name" .) .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}
