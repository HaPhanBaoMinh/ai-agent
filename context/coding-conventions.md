# Coding Conventions

- Prefer simple, explicit Helm values over hidden template behavior.
- Keep chart templates small and readable.
- Use stable Kubernetes labels based on `app.kubernetes.io/*`.
- Keep Minikube-specific settings in `values-minikube.yaml`.
- Do not add production cloud assumptions.
- Use local scripts when an in-cluster Job would add unnecessary complexity.
- Document every operational shortcut in README or `docs/operations.md`.
