## Requirements

For running the examples, the following packages are required:


    docker
    fluxcd
    git
    kubectl
    kubernetes-helm
    minikube


I installed them using `nix-shell`.


## Bootstrapping Flux

First, the cluster needs to be spun up:

    minikube start

After creating a repository on Github (janlikar/hiringhw) we can bootstrap flux:

    flux bootstrap git \
      --components-extra=image-reflector-controller,image-automation-controller \
      --url=ssh://git@github.com/janlikar/hiringhw \
      --branch=main \
      --private-key-file=/home/jan/.ssh/id_ed25519 \
      --path=clusters/production


## Installing a Helm chart

A helm chart to install Wordpress can be generated using the following commands:

    flux create source helm wordpress --url https://charts.bitnami.com/bitnami --export > clusters/production/wordpress-source.yml
    flux create hr wordpress --chart wordpress --source HelmRepository/wordpress --export > clusters/production/wordpress.yml

We need to add the following lines to `spec` in `clusters/production/wordpress.yml`[^1]:

    values:
      image:
        tag: 6.4.2
      service:
        type: NodePort


Then we can commit & push the generated files:

    git add clusters/production/wordpress-source.yml clusters/production/wordpress.yml && git commit -m "Add wordpress"


## Enabling automatic image updates


    flux create image repository wordpress --image bitnami/wordpress --export > clusters/production/wordpress-repository.yml
    flux create image policy wordpress --image-ref=wordpress --select-semver=6.4.x --export > ./clusters/production/wordpress-policy.yaml


Add the `# {"$imagepolicy": "flux-system:wordpress"}` comment next to a tag specifier in `clusters/production/wordpress-repository.yml`.

Finally, we generate an ImageUpdateAutomation and push it to our git repo:

    flux create image update flux-system \
    --interval=30m \
    --git-repo-ref=flux-system \
    --git-repo-path="./clusters/production" \
    --checkout-branch=main \
    --push-branch=main \
    --author-name=fluxcdbot \
    --author-email=fluxcdbot@users.noreply.github.com \
    --commit-template="{{range .Updated.Images}}{{println .}}{{end}}" \
    --export > ./clusters/production/flux-system-automation.yaml

    git add clusters/production/flux-system-automation.yaml
    git commit -m "Enable image automation"
    git push


[^1]: In real world applications we would probabaly use a LoadBalancer, not NodePort, for `service.type`.