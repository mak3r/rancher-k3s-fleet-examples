# System Upgrade Controller

## Prep

1. Label each cluster

    * Cluster one 
        * `arch=amd`
        * `geo=NY`
    * Cluster two 
        * `arch=amd`
        * `geo=TX`
    * Cluster three 
        * `arch=arm`
        * `geo=NY`

1. Make sure the `https://github.com/mak3r/fleet-demo-src/upgrades/plan.yaml` exhibits an upgrade for demo k3s version.

## Demo

1. Create a cluster group for `arch=arm`

1. Connect the git repo https://github.com/rancher/system-upgrade-controller
    * Set branch to `master`
    * Set path to `manifests`
    * Select `All clusters`

1. Connect the git repo https://github.com/mak3r/fleet-demo-src

    * Set brancher to `main`
    * Set path to `upgrades`
    * Select `Arm` cluster group

1. Return to Rancher UI and view upgraded k3s versions