SHELL := /bin/bash
.PHONY: sleep destroy all rancher step_01 step_02 step_03 step_04
K3S_TOKEN="mak3rVA87qPxet2SB8BDuLPWfU2xnPUSoETYF"
RANCHER_VERSION="2.5.8"
RANCHER_IMAGE_TAG="--set rancherImageTag=master-head"
SERVER_NUM=-1
ADMIN_SECRET="LJLJPIYEoiuk9kkj23p77i"
K3S_CHANNEL=v1.20
K3S_UPGRADE_CHANNEL=v1.18
export KUBECONFIG=kubeconfig

destroy:
	-rm kubeconfig kubeconfig_cluster_one kubeconfig_cluster_two kubeconfig_cluster_three kubeconfig_all
	cd terraform-setup && terraform destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

all: step_01 sleep step_02 sleep step_03 sleep step_04 
rancher: step_01 sleep step_02 sleep step_03

sleep:
	sleep 60

step_01:
	echo "Creating infrastructure"
	cd terraform-setup && terraform init && terraform apply -auto-approve

step_02: 
	echo "Creating k3s cluster on ubuntu vms 0,1,2"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 K3S_CLUSTER_INIT=1 sh -"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig


step_03: 
	echo "Installing cert-manager and Rancher"
	helm repo update
	helm upgrade --install \
		  cert-manager jetstack/cert-manager \
		  --namespace cert-manager \
		  --version v1.0.3 --create-namespace --set installCRDs=true
	kubectl rollout status deployment -n cert-manager cert-manager
	kubectl rollout status deployment -n cert-manager cert-manager-webhook
	helm upgrade --install rancher rancher-stable/rancher \
	  --namespace cattle-system \
	  --version ${RANCHER_VERSION} \
	  --set hostname=rancher-demo.mak3r.design \
	  ${RANCHER_IMAGE_TAG} \
	  --create-namespace 
	kubectl rollout status deployment -n cattle-system rancher
	kubectl -n cattle-system wait --for=condition=ready certificate/tls-rancher-ingress

step_04: 
	#Install k3s on the individual clusters
	source get_env.sh && echo $${IP0}
	# The first amd cluster
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP3} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP3}' INSTALL_K3S_CHANNEL=$(K3S_UPGRADE_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP3}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_one
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP3}/g" kubeconfig_cluster_one
	# The second amd cluster
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP4} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP4}' INSTALL_K3S_CHANNEL=$(K3S_UPGRADE_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP4}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_two
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP4}/g" kubeconfig_cluster_two
	# The arm cluster
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP5} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP5}' INSTALL_K3S_CHANNEL=$(K3S_UPGRADE_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP5}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_three
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP5}/g" kubeconfig_cluster_three

gpu: step_04
	#Install k3s on the individual clusters
	source get_env.sh && echo $${IP6}
	# The GPU cluster
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP6} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP6}' INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP6}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_one
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP6}/g" kubeconfig_cluster_four

add_node:
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP${SERVER_NUM}} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP${SERVER_NUM}}' INSTALL_K3S_CHANNEL=$(K3S_UPGRADE_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP${SERVER_NUM}}:/etc/rancher/k3s/k3s.yaml kubeconfig_cluster_${SERVER_NUM} && sed -i "" 's/default/00${SERVER_NUM}/g' ./kubeconfig_cluster_${SERVER_NUM}
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP${SERVER_NUM}}/g" kubeconfig_cluster_three

one_kubeconfig: 
	sed -i "" 's/default/one/g' ./kubeconfig_cluster_one
	sed -i "" 's/default/two/g' ./kubeconfig_cluster_two
	sed -i "" 's/default/three/g' ./kubeconfig_cluster_three
	#sed -i "" 's/default/four/g' ./kubeconfig_cluster_four
	sed -i "" 's/default/rancher/g' ./kubeconfig
	KUBECONFIG=./kubeconfig:./kubeconfig_cluster_one:./kubeconfig_cluster_two:./kubeconfig_cluster_three kubectl config view --flatten > ./kubeconfig_all
	#KUBECONFIG=./kubeconfig:./kubeconfig_cluster_one:./kubeconfig_cluster_two:./kubeconfig_cluster_three:./kubeconfig_cluster_four kubectl config view --flatten > ./kubeconfig_all

join_rancher: one_kubeconfig
	# pull the rancher-cluster.sh script
	curl -L -O https://raw.githubusercontent.com/mak3r/rancher-api-demo/master/rancher-cluster.sh
	# first login requires -z arg to change the password and set url
	export KUBECONFIG=./kubeconfig_all; \
	kubectx one; \
	source ./rancher-cluster.sh && create_cluster -i  -k -n one -s https://rancher-demo.mak3r.design -u "admin" -z ${ADMIN_SECRET} -x
	# all successive logins just use the admin secret which is now the correct password
	export KUBECONFIG=./kubeconfig_all; \
	kubectx two; \
	source ./rancher-cluster.sh && create_cluster -i  -k -n two -s https://rancher-demo.mak3r.design -u "admin" -p ${ADMIN_SECRET} -x
	export KUBECONFIG=./kubeconfig_all; \
	kubectx three; \
	source ./rancher-cluster.sh && create_cluster -i  -k -n three -s https://rancher-demo.mak3r.design -u "admin" -p ${ADMIN_SECRET} -x
