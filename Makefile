SHELL := /bin/bash
# Default target
.DEFAULT_GOAL := help

RED    := \033[1;31m
YELLOW := \033[1;33m
GREEN  :="\033[1;32m"
CYAN   := \033[1;36m
RESET  := \033[0m

.PHONY: help #- Show targets
.PHONY: setup-minikube #- Ensure Minikube cluster is running with correct profile
.PHONY: setup-argocd 
.PHONY: create-argocd-dev-application-and-status-check # Create ArgoCD Application in dev environment and check status
.PHONY: check-both-status-dimensions-sync-and-health-for-dev-application
#.PHONY: understand-gitops-in-argocd-with-drift-detection
#.PHONY: understand-sync-mode-strategies-for-dev-satging-and-prod-environment
#.PHONY: understand-sync-waves-and-how-to-handle-resource-order
#.PHONY: understand-app-of-apps-pattern-one-root-application-manages-other-applications

# Self-documenting help: list targets with "##" comments
help: ## Show all available targets with short descriptions.
	# This target reads the Makefile and prints any line ending with ##.
	# Use this when you want to discover available commands quickly.
	# Expected output: a list of targets and one-line descriptions.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  %-28s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# Convenience wrapper to call setup Makefile targets
setup-minikube: ## Ensure Minikube cluster is running with correct profile
	@echo -e "$(CYAN) Ensure Minikube cluster is running with correct profile $(RESET)"; \
	$(MAKE) -f Makefile_Setup ensure-minikube
	$(MAKE) -f Makefile_Setup enable-minikube-addons
	$(MAKE) -f Makefile_Setup check-clusterinfo
	$(MAKE) -f Makefile_Setup kubectl-get-nodes

setup-argocd: ## 
	@printf '$(CYAN) %s $(RESET) \n' \
		' What will we do to setup ArgoCD: ' \
		' 		- Step 1. Setup Minikube ' \
		' 		- Step 2. Create Namespace and Install ArgoCD on minikube ' \
		' 		- Step 3. ArgoCD Initial Setup (CLI install, Server Access, CLI login, Update Password ) ' \
		' 		- Step 4. Make ArgoCD installation production ready by hardening installation' \
		' 		- Step 5. Register the public Helm OCI repo as a source for hel chart with ArgoCD'; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to continue..."; \
	read -r _

	@printf '$(CYAN) %s $(RESET) \n' "Step 1. Setup Minikube"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 1...";  \
	read -r _; \
	$(MAKE) setup-minikube; \
	echo " --------------------------------------------------------------------------------"

	@printf '$(CYAN) %s $(RESET) \n' "Step 2. Install ArgoCD on minikube"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 2..."; \
	read -r _; \
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering install_argocd_on_minikube; \
	echo " --------------------------------------------------------------------------------"

	@printf '$(CYAN) %s $(RESET) \n' \
		' Step 3. ArgoCD Initial Setup: ' \
		' 		- Access Argocd server UI ' \
		' 		- Get Initial Argocd Server Admin Password ' \
		' 		- Install Argocd CLI tool ' \
		' 		- Change UI Admin Password ' \
		'		- Login into Argocd Server UI ' \
		' 		- Optional: Delete Initial Adming Password '; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 3..."; \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering access-argocd-server-ui-and-do-initial-configuration

	@printf '$(CYAN) %s $(RESET) \n' \
		' Step 4. Make ArgoCD installation production ready by hardening installation: ' \
		' 		- Disable-insecure-mode-of-argocd-server-by-applying-patch ' \
		' 		- Set-resource-tracking-method-to-annotation-by-applying-patch ' \
		' 		- Configure-resource-health-checks-timeout-by-applying-patch ' \
		' 		- Restart-argocd-server-to-pick-up-config-changes-by-applying-patch '; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 4..."; \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering make-argocd-installation-production-ready-by-hardening-installation

	@printf '$(CYAN) %s $(RESET) \n' \
		' Step 5. Register the public Helm OCI repo as a source for hel chart with ArgoCD'; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 5..."; \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering k8s-apply-argocd-oci-helm-lab-repo-secret
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering register-public-helm-oci-repo-as-source-for-helm-chart-with-argocd

reset-everything-for-application-for-dev-environment: ## Delete ArgoCD dev app, project entry and dev namespace (for local reset)
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications reset-application-for-dev-environment
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications verify-reset-application-for-dev-environment-done-successfully

create-argocd-dev-application-and-status-check: ## Create ArgoCD Application in dev environment and check status
	@printf '$(CYAN) %s $(RESET) \n' \
		' An ArgoCD Application is a Kubernetes custom resource that declares: ' \
		' 		- Where is the desired state? (Git repo + path + revision) ' \
		' 		- Where should it be deployed? (cluster + namespace) ' \
		' 		- How should it be rendered? (Helm, Kustomize, plain YAML) ' \
		' 		- What sync policy? (manual or automated)'; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to continue..."; \
	read -r _

	@printf '$(CYAN) %s $(RESET) \n' \
		' What will we do to setup ArgoCD: ' \
		' 		- Step 1. Create namespace where argocd application deploy in dev and staging environment ' \
		' 		- Step 1.1. Add two labels to dev and staging namespaces associated with env and ownerteam ' \
		'       - Step 1.2. Create ArgoCD AppProject for myapp-team ' \
		' 		- Step 2. Apply Dev argocd application to cluster' \
		' 		- Step 3. Watch Status-of-dev-argocd-application-in-argocd-namespace' \
		' 		- Step 4. Get Detailed-status-of-dev-argocd-application' \
		' 		- Step 5. See Resources-Argocd-created-for-dev-argocd-application' \
		' 		- Step 6. See Diff-between-desired-and-actual-for-dev-argocd-application'; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to continue..."; \
	read -r _

	@printf '$(CYAN) %s $(RESET) \n' \
		'Step 1. Create namespace where argocd application deploy in dev and staging environment' \
		'	Step 1.1. Add two labels to dev and staging namespaces associated with env and ownerteam' \
		'	Step 1.2. Create ArgoCD AppProject for myapp-team'; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 1 and 1.1...";  \
	read -r _

	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-create-namespace-where-argocd-application-deploy-in-dev-environment
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-add-two-labels-to-dev-namespace-associated-with-env-and-ownerteam
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-create-namespace-where-argocd-application-deploy-in-staging-environment
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-add-two-labels-to-staging-namespace-associated-with-env-and-ownerteam
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-apply-argocd-app-project-to-argocd-namespace

	@printf '$(CYAN) %s $(RESET) \n' "Step 2. Apply Dev argocd application to cluster"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 2...";  \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-apply-dev-argocd-application-to-cluster

	@printf '$(CYAN) %s $(RESET) \n' "Step 3. Watch Status-of-dev-argocd-application-in-argocd-namespace"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 3...";  \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-watch-status-of-dev-argocd-application-in-argocd-namespace

	@printf '$(CYAN) %s $(RESET) \n' "Step 4. Get Detailed-status-of-dev-argocd-application"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 4...";  \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-get-detailed-status-of-dev-argocd-application

	@printf '$(CYAN) %s $(RESET) \n' "Step 5. See Resources-Argocd-created-for-dev-argocd-application"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 5...";  \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-see-resources-argocd-created-for-dev-argocd-application

	@printf '$(CYAN) %s $(RESET) \n' "Step 6. See Diff-between-desired-and-actual-for-dev-argocd-application"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 6...";  \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications k8s-see-diff-between-desired-and-actual-for-dev-argocd-application


check-both-status-dimensions-sync-and-health-for-dev-application:
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications review-argocd-dev-application-two-status-dimensions-sync-and-health



# understand-gitops-in-argocd-with-drift-detection:
# 	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications explore-drift-detection-to-understand-gitops-in-argocd

# understand-sync-mode-strategies-for-dev-satging-and-prod-environment:
# 	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications explore-sync-strategies-when-to-use-each-mode

# understand-sync-waves-and-how-to-handle-resource-order:
# 	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications explore-sync-waves-handle-resource-order-when-resource-A-depends-on-resource-B-etc

# understand-app-of-apps-pattern-one-root-application-manages-other-applications:
# 	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Applications explore-app-of-apps-pattern-one-root-application-manages-other-applications


# Example: safe usage pattern
# Start from a clean shell.
# Run:
# bash
# make setup-minikube
# This ensures k8s-learning profile is up and configured.

# Then run:
# bash
# make setup-argocd
