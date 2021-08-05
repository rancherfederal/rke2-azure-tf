# Example RKE2 Deployment

This is an example RKE2 deployment which uses the main module at the root of this repo to deploy RKE2

## Quick Deployment

- Run from this examples directory, e.g. `cd examples/quickstart`
- Copy `terraform.tfvars.sample` to `terraform.tfvars` 
- Change `cluster_name` and other settings, but most can be left as the defaults 
- Run `terraform apply -auto-approve`

## Connect 

For kubectl

```bash
source ../scripts/fetch-kubeconfig.sh
kubectl get nodes
```

For SSH

```bash
../scripts/fetch-ssh-key.sh
```