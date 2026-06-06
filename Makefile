SHELL := /bin/bash

NAMESPACE ?= ai-platform
ARGOCD_NAMESPACE ?= argocd
TARGET_HOST ?= 10.50.1.20

.PHONY: minikube-start verify-cluster argocd-install argocd-port-forward helm-deps helm-lint helm-template deploy status port-forward-9router port-forward-qdrant port-forward-qdrant-mcp test-qdrant test-9router logs-9router logs-qdrant seed-context-local build-qdrant-mcp-image build-context-seeder-image clean

minikube-start:
	minikube start

verify-cluster:
	@echo "Current Kubernetes context:"
	@kubectl config current-context
	@echo
	@echo "Cluster info:"
	@kubectl cluster-info
	@echo
	@echo "Nodes:"
	@kubectl get nodes -o wide
	@echo
	@context="$$(kubectl config current-context)"; \
	nodes="$$(kubectl get nodes -o wide)"; \
	if [[ "$$context" != *minikube* && "$$nodes" != *"$(TARGET_HOST)"* ]]; then \
		echo "ERROR: target is not clearly Minikube on $(TARGET_HOST). Stop."; \
		exit 1; \
	fi

argocd-install: verify-cluster
	kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-port-forward:
	kubectl -n $(ARGOCD_NAMESPACE) port-forward svc/argocd-server 8080:443

helm-deps:
	helm dependency update charts/qdrant
	helm dependency update charts/9router || true
	helm dependency update charts/qdrant-mcp || true
	helm dependency update charts/context-seeder || true

helm-lint:
	helm lint charts/qdrant
	helm lint charts/9router
	helm lint charts/qdrant-mcp
	helm lint charts/context-seeder

helm-template:
	helm template qdrant charts/qdrant -f charts/qdrant/values-minikube.yaml
	helm template 9router charts/9router -f charts/9router/values-minikube.yaml
	helm template qdrant-mcp charts/qdrant-mcp -f charts/qdrant-mcp/values-minikube.yaml
	helm template context-seeder charts/context-seeder -f charts/context-seeder/values-minikube.yaml

deploy: verify-cluster
	kubectl apply -f clusters/argo/namespace.yaml
	kubectl apply -f clusters/argo/root-app.yaml

status:
	kubectl get ns
	kubectl -n $(ARGOCD_NAMESPACE) get applications || true
	kubectl -n $(NAMESPACE) get pods
	kubectl -n $(NAMESPACE) get svc

port-forward-9router:
	kubectl -n $(NAMESPACE) port-forward svc/9router 20128:20128

port-forward-qdrant:
	kubectl -n $(NAMESPACE) port-forward svc/qdrant 6333:6333

port-forward-qdrant-mcp:
	kubectl -n $(NAMESPACE) port-forward svc/qdrant-mcp 8000:8000

test-qdrant:
	curl -sS http://127.0.0.1:6333
	curl -sS http://127.0.0.1:6333/collections/project-context || true

test-9router:
	curl -i http://127.0.0.1:20128/dashboard || true
	curl -sS http://127.0.0.1:20128/v1/models -H "Authorization: Bearer $${OPENAI_API_KEY}" || true

logs-9router:
	kubectl -n $(NAMESPACE) logs -l app.kubernetes.io/name=9router --tail=200

logs-qdrant:
	kubectl -n $(NAMESPACE) logs -l app.kubernetes.io/name=qdrant --tail=200

seed-context-local:
	QDRANT_URL=http://127.0.0.1:6333 COLLECTION_NAME=project-context python3 scripts/seed_context.py --context-dir context

build-qdrant-mcp-image:
	eval "$$(minikube docker-env)" && docker build -t qdrant-mcp:local -f charts/qdrant-mcp/Dockerfile charts/qdrant-mcp

build-context-seeder-image:
	eval "$$(minikube docker-env)" && docker build -t context-seeder:local -f charts/context-seeder/Dockerfile .

clean:
	@echo "No destructive cleanup is automated. Delete resources manually only after verifying the Minikube target."
