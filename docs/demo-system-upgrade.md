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

## Demo

1. Connect the git repo https://github.com/rancher/system-upgrade-controller
1. Set branch to `master`
1. Set path to `manifests`
1. Select `All clusters`

1. Create a cluster group for `arch=arm`

1. Connect the git repo https://github.com/mak3r/fleet-demo-src
1. Set brancher to `main`
1. Set path to `upgrades`
1. Select `Arm` cluster group