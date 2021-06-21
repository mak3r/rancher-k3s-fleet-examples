# Overlay demo

1. Run the standard deployment https://github.com/mak3r/rancher-k3s-fleet-examples/blob/master/docs/demo-standard-deployment.md
1. Go to the source code in IDE
    1. `cp -r mods/hello-world/* live/hello-world/.`
    1. `git add live && git commit -m "demo live overlay" && git push`
1. Go to the browser and view app changes live