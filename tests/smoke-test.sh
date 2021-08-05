#!/bin/bash

DIRECTORY=$(dirname $0)

# Import testing library
eval "$(curl -q -s https://raw.githubusercontent.com/coryb/osht/master/osht.sh)"
OSHT_JUNIT=1
PLAN 4

which kubectl > /dev/null || { echo -e "💥 Error! Command kubectl not installed"; exit 1; }
kubectl version > /dev/null 2>&1 || { echo -e "💥 Error! kubectl is not pointing at a cluster, configure KUBECONFIG or $HOME/.kube/config"; exit 1; }

readyNodes=0
echo "💠 Checking nodes..."
for i in {1..12}; do
  readyNodes=$(kubectl get nodes | grep Ready | wc -l)
  if (( "$readyNodes" >= 3 )); then
    echo "✅ Cluster has $readyNodes nodes ready"
    break
  fi
  echo "⏰ waiting 10 seconds for at least 3 nodes to be ready..."
  sleep 10
done
IS "$readyNodes" -ge 3

echo "🚀 Creating smoke test resources..."

kubectl apply -f ${DIRECTORY}/load-balancer.yaml > /dev/null
kubectl apply -f ${DIRECTORY}/pvc-pod.yaml > /dev/null

echo "🔍 Polling resources..."

externalIp=""
for i in {1..12}; do
  externalIp=$(kubectl get service/test-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [[ "$externalIp" != "" ]]; then
    echo "✅ SERVICE: test-svc has external IP '$externalIp'"
    break
  fi
  echo "⏰ waiting 10 seconds for load-balancer to be ready..."
  sleep 10
done
IS $externalIp != ""

for i in {1..12}; do
  pvcStatus=$(kubectl get pvc test-pvc-azure-disk | grep test-pvc-azure-disk | awk '{print $2}')
  if [[ "$pvcStatus" == "Bound" ]]; then
    echo "✅ PVC: test-pvc-azure-disk is 'Bound'"
    break
  fi
  echo "⏰ waiting 10 seconds for test-pvc-azure-disk to be bound..."
  sleep 10
done
IS $pvcStatus == "Bound"

podStatus=""
for i in {1..12}; do
  podStatus=$(kubectl get po test-pod | grep test-pod | awk '{print $3}')
  if [[ "$podStatus" == "Running" ]]; then
    echo "✅ POD: test-pod is 'Running'"
    break
  fi
  echo "⏰ waiting 10 seconds for test-pod to start..."
  sleep 10
done
IS $podStatus == "Running"

echo "❌ Removing smoke test resources..."
kubectl delete -f ${DIRECTORY}/load-balancer.yaml --wait=false
kubectl delete -f ${DIRECTORY}/pvc-pod.yaml --wait=false
kubectl delete pvc test-pvc-azure-disk --wait=false
