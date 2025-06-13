## Debugging

### Diagnosing the NotReady Node in Kind

To understand why your k8s-poc-cluster-control-plane is NotReady, we need to inspect the kubelet logs from within that node's container. Kind runs each Kubernetes node as a Docker container.

Get the Docker Container ID for your control plane node:

```Bash
docker ps -a --filter "name=k8s-poc-cluster-control-plane" --format "{{.ID}}"
```

Access the kubelet logs inside the control plane node container:
Replace <container-id> with the ID you got from the previous step.

```Bash
docker exec <container-id> journalctl -u kubelet

kubectl logs -n ingress-nginx $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')

# Get the latest NodePort
NODE_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
echo "Using NodePort: $NODE_PORT"

curl http://localhost:$NODE_PORT/nginx
curl http://localhost:$NODE_PORT/apache

kubectl describe pod -n my-app-dev $(kubectl get pods -n my-app-dev -l app=nginx-configmap -o jsonpath='{.items[0].metadata.name}')

kubectl describe pod -n my-app-dev $(kubectl get pods -n my-app-dev -l app=apache -o jsonpath='{.items[0].metadata.name}')

kubectl get endpoints -n my-app-dev nginx-clusterip
kubectl get endpoints -n my-app-dev apache-clusterip

kubectl describe service -n my-app-dev nginx-clusterip

kubectl get pods -n my-app-dev -l app=apache -o jsonpath='{.items[0].metadata.name}'

# Accessing pod shell
kubectl exec -it <YOUR_APACHE_POD_NAME> -n my-app-dev -- sh

curl http://localhost:80/

# Accessing pod shell of any one container
kubectl exec -it $(kubectl get pods -n my-app-dev -l app=nginx-configmap -o jsonpath='{.items[0].metadata.name}') -n my-app-dev -- sh

curl http://apache-clusterip/

kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}'

kubectl logs -n ingress-nginx $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}') -f

```