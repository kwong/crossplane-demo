{{- define "service.labels" -}}
app: {{ .Values.service.name }}
cluster_name: {{ .Values.clusterName }}
environment: {{ .Values.env }}
logging_enabled: "true"
prometheus_custom_metrics: "true"
service_group: {{ .Values.service.group }}
service_name: {{ .Values.service.name }}
service_type: {{ .Values.service.type }}
{{- end }}

{{ define "service.fullname" -}}
{{ .Values.service.name }}
{{- end }}