# INSTALL INGRESS NGINX WITH HELM (ENABLE "HOSTPORT" LISTEN PORTS 80, 443 ON NODE CONTAINED INGRESS NGINX CONTROLLER POD)
https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx

**Install ingress nginx**
```
root@master01:~# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
root@master01:~# helm repo update
root@master01:~# helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.enabled=false \
  --set controller.kind=DaemonSet \
  --set controller.ingressClass=nginx \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.default=true \
  --set controller.hostPort.enabled=true \
  --set controller.hostPort.ports.http=80 \
  --set controller.hostPort.ports.https=443


NAME: ingress-nginx
LAST DEPLOYED: Thu Feb 20 16:09:14 2025
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'
...  
```

```
root@master01:~# kubectl get all -o wide -n ingress-nginx
NAME                                 READY   STATUS    RESTARTS   AGE     IP             NODE       NOMINATED NODE   READINESS GATES
pod/ingress-nginx-controller-brxl7   1/1     Running   0          2m14s   10.44.19.65    worker03   <none>           <none>
pod/ingress-nginx-controller-d4xmv   1/1     Running   0          2m14s   10.44.5.13     worker01   <none>           <none>
pod/ingress-nginx-controller-mggc6   1/1     Running   0          2m14s   10.44.196.66   worker04   <none>           <none>
pod/ingress-nginx-controller-xt9rp   1/1     Running   0          2m14s   10.44.30.65    worker02   <none>           <none>

NAME                                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/ingress-nginx-controller-admission   ClusterIP   10.45.53.248   <none>        443/TCP   2m14s   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE     CONTAINERS   IMAGES                                                                                                                     SELECTOR
daemonset.apps/ingress-nginx-controller   4         4         4       4            4           kubernetes.io/os=linux   2m14s   controller   registry.k8s.io/ingress-nginx/controller:v1.12.0@sha256:e6b8de175acda6ca913891f0f727bca4527e797d52688cbe9fec9040d6f6b6fa   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
```

**Test ingress state**
```
# curl <WORKER_NODE_IP>

Example:
root@master01:~# curl 172.31.36.12
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

**Set tolerations for ingress nginx controller daemonset schedule pod to master nodes (optional)**
```
root@master01:~# kubectl edit  daemonset.apps/ingress-nginx-controller -n ingress-nginx
---
...
spec:
  tolerations:
  - key: "CriticalAddonsOnly"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
  containers:
  ...

```

```
root@master01:~# kubectl get all -o wide -n ingress-nginx
NAME                                 READY   STATUS    RESTARTS   AGE     IP             NODE       NOMINATED NODE   READINESS GATES
pod/ingress-nginx-controller-66hhm   1/1     Running   0          3m9s    10.44.59.193   master02   <none>           <none>
pod/ingress-nginx-controller-8djzb   1/1     Running   0          71s     10.44.19.66    worker03   <none>           <none>
pod/ingress-nginx-controller-8tszh   1/1     Running   0          2m15s   10.44.196.68   worker04   <none>           <none>
pod/ingress-nginx-controller-bxdcp   1/1     Running   0          2m37s   10.44.30.66    worker02   <none>           <none>
pod/ingress-nginx-controller-cqc8g   1/1     Running   0          3m9s    10.44.235.1    master03   <none>           <none>
pod/ingress-nginx-controller-cz6qp   1/1     Running   0          103s    10.44.5.14     worker01   <none>           <none>
pod/ingress-nginx-controller-nb6vz   1/1     Running   0          3m9s    10.44.241.69   master01   <none>           <none>

NAME                                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/ingress-nginx-controller-admission   ClusterIP   10.45.53.248   <none>        443/TCP   14m   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE   CONTAINERS   IMAGES                                                                                                                     SELECTOR
daemonset.apps/ingress-nginx-controller   7         7         7       7            7           kubernetes.io/os=linux   14m   controller   registry.k8s.io/ingress-nginx/controller:v1.12.0@sha256:e6b8de175acda6ca913891f0f727bca4527e797d52688cbe9fec9040d6f6b6fa   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
```
