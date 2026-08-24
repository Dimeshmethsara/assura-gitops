{{- define "assura-frontend.name" -}}
assura-frontend
{{- end -}}

{{- define "assura-frontend.labels" -}}
app.kubernetes.io/name: {{ include "assura-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
