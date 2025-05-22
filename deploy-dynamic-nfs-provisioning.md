# Deploy Dynamic NFS Provisioning

**Install "nfs-common" package on all nodes (master & worker)**
```
# apt install -y nfs-common
```


**Deploy dynamic NFS provisioning syntax:**
```
# kubectl create ns nfs-share
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
# helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -n nfs-share \
        --set nfs.server=<NFS_SERVER_IP> \
        --set nfs.path=/nfs/share \
        --set storageClass.name=nfs-client \
        --set storageClass.reclaimPolicy=Retain \
        --set storageClass.defaultClass=true
```

**Example:**
```
root@master02:~# kubectl create ns nfs-share
namespace/nfs-share create
```
```
root@master02:~# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
"nfs-subdir-external-provisioner" has been added to your repositories

root@master02:~# helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -n nfs-share \
        --set nfs.server=172.31.33.41 \
        --set nfs.path=/nfs/share \
        --set storageClass.name=nfs-client \
        --set storageClass.reclaimPolicy=Retain \
        --set storageClass.defaultClass=true
NAME: nfs-provisioner
LAST DEPLOYED: Fri Feb 21 10:48:04 2025
NAMESPACE: nfs-share
STATUS: deployed
REVISION: 1
TEST SUITE: None
```
```
root@master02:~# kubectl get all -n nfs-share
NAME                                                                  READY   STATUS    RESTARTS   AGE
pod/nfs-provisioner-nfs-subdir-external-provisioner-58546d494-4chn9   1/1     Running   0          2m4s

NAME                                                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nfs-provisioner-nfs-subdir-external-provisioner   1/1     1            1           2m4s

NAME                                                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/nfs-provisioner-nfs-subdir-external-provisioner-58546d494   1         1         1       2m4s
```
```
root@master02:~# kubectl get sc
NAME                   PROVISIONER                                                     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client (default)   cluster.local/nfs-provisioner-nfs-subdir-external-provisioner   Retain          Immediate           true                   3m9s
```

**Test:**

*Test create PVC*

```
root@master02:~# vi pvc-test-nfs.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-21022025
  namespace: default
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi


root@master02:~# kubectl apply -f pvc-test-nfs.yaml
persistentvolumeclaim/test-nfs-21022025 created


root@master02:~# kubectl get pv,pvc -n default
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/pvc-b9ffa0c8-5443-480f-a0f1-663be860757f   5Gi        RWO            Retain           Bound    default/test-nfs-21022025   nfs-client     <unset>                          25s

NAME                                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/test-nfs-21022025   Bound    pvc-b9ffa0c8-5443-480f-a0f1-663be860757f   5Gi        RWO            nfs-client     <unset>                 25s
```

*Check in share volume mount point in NFS Server*
```
root@nfs-server:~# cd /nfs/share
root@nfs-server:/nfs/share# ls -la
total 12
drwxr-xr-x 3 nobody root 4096 Feb 21 11:06 .
drwxr-xr-x 3 nobody root 4096 Jan 17 09:34 ..
drwxrwxrwx 2 root   root 4096 Feb 21 11:05 default-test-nfs-21022025-pvc-b9ffa0c8-5443-480f-a0f1-663be860757f
```