# assura-gitops

Everything ArgoCD watches for the Assura FAMS deployment. Terraform (`assura-infra`) applies
exactly one thing directly into the cluster — the ArgoCD Helm release plus this repo's
`bootstrap/root-app.yaml` — and from that point on, **ArgoCD is the only thing that touches the
cluster**. Jenkins pushes images and edits one line in this repo; it never runs `kubectl`.

## Layout

- `bootstrap/root-app.yaml` — the App-of-Apps entrypoint Terraform applies once.
- `apps/*.yaml` — one ArgoCD `Application` per platform component or workload, sequenced by `argocd.argoproj.io/sync-wave` (0 = namespaces, 1 = operators, 2 = policies/observability, 3 = Jenkins, 4 = the two app charts).
- `manifests/namespaces/` — plain `Namespace` objects (with Pod Security Standards labels), synced at wave 0.
- `charts/assura-backend/`, `charts/assura-frontend/` — this project's own Helm charts. `values-image.yaml` in each is the **only** file Jenkins ever edits (via `yq`, see each app repo's `Jenkinsfile`).
- `charts/kyverno-policies/` — the `ClusterPolicy` set enforcing this project's security baseline in the `assura-app` namespace.

## Before this actually works: fill in the placeholders

This repo intentionally contains **no real secrets or account-specific values** — only
placeholders (`187691954427`, `CHANGE_ME...`) marked with `# CHANGE ME` comments. After
`assura-infra`'s first `terraform apply`, replace every one of them using the mapping in
`assura-infra/README.md`. This is a one-time bootstrap step per AWS account, done once and
committed — these are account constants (IAM role ARNs, ECR URLs, Secrets Manager ARNs), not
secrets themselves.

Files with placeholders: `apps/01-external-secrets.yaml`, `apps/01-aws-load-balancer-controller.yaml`,
`apps/02-fluent-bit.yaml`, `apps/03-jenkins.yaml`, `charts/assura-backend/values.yaml`,
`charts/assura-frontend/values.yaml`, `charts/kyverno-policies/templates/clusterpolicies.yaml`.

Also set `ingress.host` in both app charts' `values.yaml` to your real domain (or the ALB's own
DNS name if you don't have one yet — see the deployment plan's optional `domain_name` note).

## Why this repo should be public

This repo contains **no real secrets** by design — only placeholder ARNs/account IDs (see
above). That's deliberate: it lets `assura-gitops` be a **public** GitHub repo, which means
ArgoCD needs no read credential at all to sync from it (`repoURL` in `bootstrap/root-app.yaml`
and `apps/04-*.yaml` is a plain anonymous HTTPS clone). It's also a genuine portfolio upside —
an interviewer can browse the actual GitOps structure without you granting repo access.

Jenkins still needs a **write** credential regardless of public/private, since GitHub never
allows anonymous `git push` — see `assura-infra/README.md`'s GitHub-credentials section for how
that's provisioned.

If you'd rather keep this repo private, ArgoCD will need a repository credential added as a
`Secret` labeled `argocd.argoproj.io/secret-type: repository` in the `argocd` namespace (see
ArgoCD's own docs for the exact shape) — not set up here, since it depends on a call only you can
make about this repo's visibility.

## PR validation

`.github/workflows/validate.yml` runs on every PR — plain GitHub Actions, not Jenkins-in-EKS,
deliberately: linting rendered Helm/YAML doesn't need cluster compute, so PRs here can still be
validated even while the demo cluster is fully torn down between interviews.
