# Code examples for Talk about Multi-Cluster Kubernetes Management with Rancher, K3S and Fleet

## Installation steps

1. Setup infrastructure

Fill out `terraform-setup/terraform.tfvars` with aws and digital ocean credentials.

```
make step_01
```

2. Create 3 Node HA Cluster for Rancher

```
make step_02
```

3. Install cert-manager and Rancher

```
make step_03
```

4. Create 3 single-node downstream k3s clusters

```
make step_04
```

### Configure Rancher

Go to https://rancher-demo.mak3r.design/login and set up admin password and server url.

### Add 3 downstream clusters to Rancher

"Add Cluster" -> "Register an existing Kubernetes cluster" => "Other Cluster"

Add "group" label with values "amd" and "arm".

To register every cluster run

```
./run_on.sh [3-5] kubectl apply ....
```

* Where the downstream clusters are in the array indices 3,4,5 
* Be sure to quote the command passed into `./run_on.sh` so the full command is executed remotely - unless some other behavior is desired

Wait until all clusters are read.

### Configure Fleet

Go to "Cluster Explorer" of local cluster -> "Continuous Delivery"

Add arm and amd Cluster Groups matching the cluster labels from above in "fleet-default".

## Use fleet

Get Download Kubeconfig from all clusters.

Commands to watch clusters

```
watch kubectl --kubeconfig kubeconfig_cluster_one --insecure-skip-tls-verify get nodes,pods -A
watch kubectl --kubeconfig kubeconfig_cluster_two --insecure-skip-tls-verify get nodes,pods -A
watch kubectl --kubeconfig kubeconfig_cluster_three --insecure-skip-tls-verify get nodes,pods -A
```

## Add edge fleet

### Get the registration token from the fleet manager
* Get your registration token. Here my token is named `demo-reg-token` and sits in namespace `retail-demo`

    ```
  kubectl -n retail-demo get secret demo-reg-token -o 'jsonpath={.data.values}' | base64 --decode > values.yaml
  ```

### Option 1: Helm Repo Install (cli)
* Add or update to the rancher stable repo in helm
    * Add
  
      `helm repo add rancher-stable https://releases.rancher.com/server-charts/stable`
  * Update
  
      `helm repo update`
* Change the labels according to the bundles desired 

    `CLUSTER_LABELS="--set-string labels.sitenum=NYTPICTL --set-string labels.env=PROD"`
* Install fleet agent

    ```
    helm -n fleet-system install --create-namespace --wait \
    ${CLUSTER_LABELS} \
    --values values.yaml \
    fleet-agent https://github.com/rancher/fleet/releases/download/v0.3.3/fleet-agent-0.3.3.tgz`
    ```

### Option 2: Cluster Bundled with Edge Device(s)

* Create a containerd/docker tarball of `docker.io/rancher/fleet-agent`
* Put the tarball in the images location

    `/var/lib/rancher/k3s/agent/images/`
* Create a HelmChart (CRD) configuration

  ```
  apiVersion: helm.cattle.io/v1
  kind: HelmChart
  metadata:
    name: fleet-agent
    namespace: kube-system
  spec:
    chart: "https://%{KUBERNETES_API}%/static/charts/fleet-agent-0.3.3.tgz"
    targetNamespace: fleet-system
    set:
      labels:
        sitenum: NYTURINGPI-CTL
        env: PROD
  ```
* Drop the HelmChart yaml into the manifests directory

### Option 3: Air-Gap and No Registry/Charts Access

* Create a containerd/docker tarball of `docker.io/rancher/fleet-agent`
* Put the tarball in the images location

    `/var/lib/rancher/k3s/agent/images/`
* Download stable fleet agent chart

  `curl -L -O https://github.com/rancher/fleet/releases/download/v0.3.3/fleet-agent-0.3.3.tgz`
* Drop the chart into k3s charts location

    `/var/lib/rancher/k3s/server/static/`
* Create a HelmChartConfig configuration

  ```
  apiVersion: helm.cattle.io/v1
  kind: HelmChartConfig
  metadata:
  name: fleet-agent
  namespace: fleet-system
  spec:
  valuesContent: |-
    image: fleet-agent
    imageTag: v0.3.3
    labels:
      sitenum: NY-TURINGPI-CTL
      env: PROD
  ```
* Drop the HelmChartConfig yaml into the manifests directory

### Upgrade all clusters

* Add Git repo to deploy system-upgrade-controller
    * Repo: https://github.com/rancher/system-upgrade-controller
    * Path: manifests
    * All clusters.

* Add Git Repo to deploy upgrade Plan

    * Repo: https://github.com/bashofmann/rancher-k3s-fleet-examples
    * Path: fleet-upgrades
    * Only amd clusters

* Deploy upgrade plan

* Add Git Repo to deploy rest

    * Repo: https://github.com/bashofmann/rancher-k3s-fleet-examples
    * Path: fleet-examples
    * All clusters

### Deploy applications

* Add hello-world example
* Open webapp on nodeports
* Update hello-world example with overlays
* Show that on arm cluster the color changed
* Deploy netdata
* Change gitrepo cluster selector

## Cleanup

To remove everything

```
make destroy
```