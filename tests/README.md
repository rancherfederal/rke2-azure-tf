# Smoke Tests for Bare Metal Kubernetes on Azure

These resources can be deployed to Kubernetes to validate & smoke test that the Azure cloud provider is working, in particular:
 - A service of type LoadBalancer is able to get an external IP, via an Azure LoadBalancer
 - PV and PVCs can be bound using the default storage class which should use `azure-disk` as the provisioner. See modules/custom_data/files/default-storageclass.yaml
 - Pods can mount PVCs, therefor are labeled correctly

## Running - Automated Script

Run test script, this will check the cluster nodes are ready, deploy test resources, poll for them to be in the correct statuses and states, then remove the resources.

```bash
tests/smoke-test.sh
```

## Running - Manually

Deploy all test resources

```bash
kubectl apply -f tests/
```

Validate with

```bash
kubectl get pods,svc,pvc
```

It might be several minutes before everything is ready, but you should expect to see:

- `pod/test-pod` should be **Running**
- `service/test-svc` should have an **external IP address** assigned
- `test-pvc-azure-disk` should be **Bound**

Running `kubectl describe` against any of these resources may provide additional information and trouble shooting details.

Also in the Azure resource group you should see the following resources created:

- Azure Load Balancer named `kubernetes`
- Azure Managed Disk named `kubernetes-dynamic-pvc-{some_guid}`
- Public IP named `kubernetes-{some_random_string}`
