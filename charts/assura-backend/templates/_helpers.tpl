{{- define "assura-backend.name" -}}
assura-backend
{{- end -}}

{{- define "assura-backend.labels" -}}
app.kubernetes.io/name: {{ include "assura-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
