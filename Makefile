SHELL := /bin/bash
.PHONY: sleep destroy all step_01 step_02 step_03 step_04
K3S_TOKEN="mak3rVA87qPxet2SB8BDuLPWfU2xnPUSoETYF"

export KUBECONFIG=kubeconfig

destroy:
	rm kubeconfig kubeconfig_cluster_one kubeconfig_cluster_two kubeconfig_cluster_three \
	&& cd terraform-setup && terraform destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

all: step_01 sleep step_02 sleep step_03 sleep step_04

sleep:
	sleep 60

step_01:
	echo "Creating infrastructure"
	cd terraform-setup && terraform init && terraform apply -auto-approve

step_02:
	echo "Creating k3s cluster on ubuntu vms 0,1,2"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 K3S_CLUSTER_INIT=1 sh -"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig

print_step_02:
	echo "Creating k3s cluster on ubuntu vms 0,1,2"
	source get_env.sh && echo "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 K3S_CLUSTER_INIT=1 sh -"
	source get_env.sh && echo "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && echo "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "


step_03:
	echo "Installing cert-manager and Rancher"
	helm repo update
	helm upgrade --install \
		  cert-manager jetstack/cert-manager \
		  --namespace cert-manager \
		  --version v1.0.3 --create-namespace --set installCRDs=true
	kubectl rollout status deployment -n cert-manager cert-manager
	kubectl rollout status deployment -n cert-manager cert-manager-webhook
	helm upgrade --install rancher rancher-latest/rancher \
	  --namespace cattle-system \
	  --version 2.5.3 \
	  --set hostname=rancher-demo.mak3r.design --create-namespace
	kubectl rollout status deployment -n cattle-system rancher
	kubectl -n cattle-system wait --for=condition=ready certificate/tls-rancher-ingress

step_04:
	source get_env.sh && echo $${IP0}
	# curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.18 K3S_KUBECONFIG_MODE=644 sh -
	# watch kubectl get nodes,pods,svc -A
	echo "Creating downstream k3s clusters"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP3} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP3}' INSTALL_K3S_CHANNEL=v1.18 K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP3}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_one
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP3}/g" kubeconfig_cluster_one
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP4} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP4}' INSTALL_K3S_CHANNEL=v1.18 K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP4}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_two
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP4}/g" kubeconfig_cluster_two
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP5} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP5}' INSTALL_K3S_CHANNEL=v1.18 K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP5}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_three
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP5}/g" kubeconfig_cluster_three
