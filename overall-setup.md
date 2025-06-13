## Index

```Bash
sh ./setup-cluster.sh

kubectl get nodes

kubectl apply -f my-app-namespace.yaml

kubectl get namespaces

kubectl apply -f nginx-configmap.yaml

kubectl get configmaps -n my-app-dev

kubectl apply -f nginx-deployment-with-configmap.yaml

kubectl get deployments -n my-app-dev

kubectl get pods -n my-app-dev

kubectl get replicasets -n my-app-dev

kubectl apply -f nginx-clusterip-service.yaml

kubectl get services -n my-app-dev

kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-clusterip-service.yaml

kubectl get deployments -n my-app-dev

kubectl get services -n my-app-dev

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml

kubectl get pods -n ingress-nginx

kubectl apply -f my-app-ingress.yaml

kubectl get ingress -n my-app-dev

kubectl describe ingress my-app-ingress -n my-app-dev

kubectl get svc -n ingress-nginx ingress-nginx-controller

kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 --address 0.0.0.0



```