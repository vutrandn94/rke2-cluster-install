# Remove Node From Cluster

## Step 1: Drain a Node
*https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/*

**Get all nodes**
```
# kubectl get nodes
NAME       STATUS     ROLES                       AGE   VERSION
master01   NotReady   control-plane,etcd,master   19h   v1.29.13+rke2r1
master02   Ready      control-plane,etcd,master   18h   v1.29.13+rke2r1
master03   Ready      control-plane,etcd,master   18h   v1.29.13+rke2r1
worker01   Ready      worker                      18h   v1.29.13+rke2r1
worker02   Ready      worker                      18h   v1.29.13+rke2r1
worker03   Ready      worker                      18h   v1.29.13+rke2r1
worker04   Ready      worker                      17h   v1.29.13+rke2r1
```

**Drain a node if node alive**
```
# kubectl drain --ignore-daemonsets <NODE_NAME>
# kubectl cordon <NODE_NAME>

---
Example:
# kubectl drain --ignore-daemonsets master01
Warning: ignoring DaemonSet-managed Pods: calico-system/calico-node-nkm8q, ingress-nginx/ingress-nginx-controller-nb6vz
evicting pod calico-system/calico-kube-controllers-6bf5c54b59-qs998
evicting pod tigera-operator/tigera-operator-5d7c4bffdc-9kvcr
evicting pod kube-system/rke2-coredns-rke2-coredns-58664888cf-lrxvd
pod/rke2-coredns-rke2-coredns-58664888cf-lrxvd evicted
pod/calico-kube-controllers-6bf5c54b59-qs998 evicted
pod/tigera-operator-5d7c4bffdc-9kvcr evicted
node/master01 drained

# kubectl cordon master01
node/master01 already cordoned

# kubectl get nodes
NAME       STATUS                        ROLES                       AGE   VERSION
master01   NotReady,SchedulingDisabled   control-plane,etcd,master   19h   v1.29.13+rke2r1
master02   Ready                         control-plane,etcd,master   19h   v1.29.13+rke2r1
master03   Ready                         control-plane,etcd,master   18h   v1.29.13+rke2r1
worker01   Ready                         worker                      18h   v1.29.13+rke2r1
worker02   Ready                         worker                      18h   v1.29.13+rke2r1
worker03   Ready                         worker                      18h   v1.29.13+rke2r1
worker04   Ready                         worker                      17h   v1.29.13+rke2r1
```

**Drain a node if node no longer alive**
```
# kubectl drain --ignore-daemonsets <NODE_NAME> --force --grace-period=0
# kubectl cordon <NODE_NAME>

---
Example:
# kubectl drain --ignore-daemonsets master01 --force --grace-period=0
Warning: ignoring DaemonSet-managed Pods: calico-system/calico-node-nkm8q, ingress-nginx/ingress-nginx-controller-nb6vz
evicting pod calico-system/calico-kube-controllers-6bf5c54b59-qs998
evicting pod tigera-operator/tigera-operator-5d7c4bffdc-9kvcr
evicting pod kube-system/rke2-coredns-rke2-coredns-58664888cf-lrxvd
pod/rke2-coredns-rke2-coredns-58664888cf-lrxvd evicted
pod/calico-kube-controllers-6bf5c54b59-qs998 evicted
pod/tigera-operator-5d7c4bffdc-9kvcr evicted
node/master01 drained

# kubectl cordon master01
node/master01 already cordoned

# kubectl get nodes
NAME       STATUS                        ROLES                       AGE   VERSION
master01   NotReady,SchedulingDisabled   control-plane,etcd,master   19h   v1.29.13+rke2r1
master02   Ready                         control-plane,etcd,master   19h   v1.29.13+rke2r1
master03   Ready                         control-plane,etcd,master   18h   v1.29.13+rke2r1
worker01   Ready                         worker                      18h   v1.29.13+rke2r1
worker02   Ready                         worker                      18h   v1.29.13+rke2r1
worker03   Ready                         worker                      18h   v1.29.13+rke2r1
worker04   Ready                         worker                      17h   v1.29.13+rke2r1
```

## Step 2: Delete node

```
# kubectl delete node <NODE_NAME>


---
# kubectl delete node master01
node "master01" deleted

# kubectl get nodes
NAME       STATUS   ROLES                       AGE   VERSION
master02   Ready    control-plane,etcd,master   19h   v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   19h   v1.29.13+rke2r1
worker01   Ready    worker                      18h   v1.29.13+rke2r1
worker02   Ready    worker                      18h   v1.29.13+rke2r1
worker03   Ready    worker                      18h   v1.29.13+rke2r1
worker04   Ready    worker                      17h   v1.29.13+rke2r1
```

## Step 3: Update node list info in /etc/rancher/rke2/config.yaml (Only avalable with case server deleted is master node, if server deleted is worker node please skip this step)
**Config in all remaining master nodes**

*Replace "server" values with hostname of 1 rke-server alive*

*Update "tls-san" list values remove hostname of rke-server deleted*

```
# cat /etc/rancher/rke2/config.yaml 
server: "https://master01:9345"
token: "K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df"
tls-san:
  - "master01"
  - "master02"
  - "master03"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
cni: "calico"
cluster-cidr: "10.44.0.0/16"
service-cidr: "10.45.0.0/16"
kube-apiserver-arg:
  - "feature-gates=InPlacePodVerticalScaling=true"   

# vi /etc/rancher/rke2/config.yaml
server: "https://master02:9345"
token: "K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df"
tls-san:
  - "master02"
  - "master03"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
cni: "calico"
cluster-cidr: "10.44.0.0/16"
service-cidr: "10.45.0.0/16"
kube-apiserver-arg:
  - "feature-gates=InPlacePodVerticalScaling=true"   


# systemctl restart rke2-server

# systemctl status rke2-server
● rke2-server.service - Rancher Kubernetes Engine v2 (server)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2025-02-21 09:59:57 +07; 2min 26s ago
       Docs: https://github.com/rancher/rke2#readme
    Process: 67090 ExecStartPre=/bin/sh -xc ! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service (code=exited, status=0/SUCCESS)
    Process: 67093 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
    Process: 67094 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 67095 (rke2)
      Tasks: 141
     Memory: 675.4M
        CPU: 30.344s
     CGroup: /system.slice/rke2-server.service
             ├─ 1830 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id a76bd2b5d4a3104b04dabe4dfccab94dbdb8192f5c49c3ea3d12f80ee6fd5>             ├─ 2379 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 428c7cf522cb3e15a344c9f8b13ec415d9908e45070385162c8c8a5cc180b>             ├─29286 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id fd5ec38c6d0354fcbca29ca64d69025725d8ff8103d0d47537908b48c1266>             ├─29368 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 31ec9acd44c611044f8ab9ecb2d77cfc5bdc4baa0cc823d179fde2914dd0a>             ├─29522 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 005bcd9ed5c2c3723729bc4e9ed477789757630d003bab462d60cc2607940>             ├─29527 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 21a1ef9c95d974af6249cbc3c0536b5d0ca6327284acbf1ab3dcba70f06f1>             ├─29541 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 090c71ba6132008b5c8b386f034dfca6faed308d28eeee645e3d3a1672007>             ├─67095 "/usr/local/bin/rke2 server"
             ├─67118 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/ag>             ├─67228 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --anonymous-auth=false --authentication-tok>             └─67423 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 83d43600d7e9fd99e4a570ea629fc7895cde590a728d598b5091773e3c25e>
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Starting /v1, Kind=Node controller"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Cluster dns configmap already exists"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Starting managed etcd apiserver addresses controller"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Starting managed etcd member removal controller"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Starting managed etcd snapshot ConfigMap controller"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Labels and annotations have been set successfully on node: master02"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Starting k3s.cattle.io/v1, Kind=ETCDSnapshotFile controller"
Feb 21 09:59:57 master02 rke2[67095]: time="2025-02-21T09:59:57+07:00" level=info msg="Reconciling snapshot ConfigMap data"
Feb 21 09:59:58 master02 rke2[67095]: time="2025-02-21T09:59:58+07:00" level=info msg="Starting /v1, Kind=Secret controller"
Feb 21 09:59:58 master02 rke2[67095]: time="2025-02-21T09:59:58+07:00" level=info msg="Updating TLS secret for kube-system/rke2-serving (count: 15): map[field.cattle.io/projectId:local:p-l>


# kubectl get nodes
NAME       STATUS   ROLES                       AGE   VERSION
master02   Ready    control-plane,etcd,master   19h   v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   19h   v1.29.13+rke2r1
worker01   Ready    worker                      19h   v1.29.13+rke2r1
worker02   Ready    worker                      18h   v1.29.13+rke2r1
worker03   Ready    worker                      18h   v1.29.13+rke2r1
worker04   Ready    worker                      18h   v1.29.13+rke2r1
```

**Config in all worker nodes**

*Replace "server" values with hostname of 1 rke-server alive*

```
# cat /etc/rancher/rke2/config.yaml 
server: "https://master01:9345"
token: "K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df"
node-label:
  - "node.kubernetes.io/role=worker"


# vi /etc/rancher/rke2/config.yaml
server: "https://master02:9345"
token: "K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df"
node-label:
  - "node.kubernetes.io/role=worker"

# systemctl restart rke2-agent

# systemctl status rke2-agent
● rke2-agent.service - Rancher Kubernetes Engine v2 (agent)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-agent.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2025-02-21 10:35:36 +07; 6s ago
       Docs: https://github.com/rancher/rke2#readme
    Process: 5782 ExecStartPre=/bin/sh -xc ! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service (code=exited, status=0/SUCCESS)
    Process: 5784 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
    Process: 5785 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 5786 (rke2)
      Tasks: 155
     Memory: 424.4M
        CPU: 1.801s
     CGroup: /system.slice/rke2-agent.service
             ├─1078 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 581bbea807d4084deec4501d89f8fe378aebd4b21ab38e6e0ec9a333badcc2>
             ├─1096 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 426ded81e56e0a3447554c2362b808516a1629197221d17383ed0d3974a5d7>
             ├─2176 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 8b56296abf0f275679e9ea4a1d61227883963f599dfc93a7b545077946fe39>
             ├─2255 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 74202b253124fd1727d16c554314cc80bb46974b44a024656462059637d39a>
             ├─2446 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id ed3eb8505afa9ff541caca0ebead8e228e65c4c1958095d21ec572e801f89a>
             ├─2837 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 36a484cd51d849abdcc91e63483dbfc2d43dad7966ee392756d96997e18c23>
             ├─3042 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id bf68e65bef44e51146a5eb7410b3e6e88951d020f41a11aea53fb47be4756f>
             ├─3093 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 771ce2f41cb1bb3fbac3f3d16889053bce19d18f2c74c77cab660da6e080b4>
             ├─3740 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 2df396bf22abc2da5c01ab1781e2da064d2e955f07f8c474acf88151d81b8b>
             ├─5786 "/usr/local/bin/rke2 agent"
             ├─5800 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/age>
             ├─5936 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --allowed-unsafe-sysctls=net.ipv4.ip_forward>
             └─5974 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id a5bcb7bef1167ac2a0ee7d367ee2c364924e659a61cf32c3d72c8cb5f8ddd4>

Feb 21 10:35:36 worker02 rke2[5786]: time="2025-02-21T10:35:36+07:00" level=info msg="Running kube-proxy --cluster-cidr=10.44.0.0/16 --conntrack-max-per-core=0 --conntrack-tcp-timeout-clos>
Feb 21 10:35:36 worker02 rke2[5786]: time="2025-02-21T10:35:36+07:00" level=info msg="Server 172.31.46.103:9345@RECOVERING->ACTIVE from successful health check"
Feb 21 10:35:36 worker02 rke2[5786]: time="2025-02-21T10:35:36+07:00" level=info msg="Closing 1 connections to load balancer server master02:9345@STANDBY*"
Feb 21 10:35:36 worker02 rke2[5786]: time="2025-02-21T10:35:36+07:00" level=info msg="Server 172.31.35.122:9345@UNCHECKED->RECOVERING from successful health check"
Feb 21 10:35:37 worker02 rke2[5786]: time="2025-02-21T10:35:37+07:00" level=info msg="Tunnel authorizer set Kubelet Port 0.0.0.0:10250"
Feb 21 10:35:37 worker02 rke2[5786]: time="2025-02-21T10:35:37+07:00" level=info msg="Server 172.31.35.122:6443@RECOVERING->ACTIVE from successful health check"
Feb 21 10:35:37 worker02 rke2[5786]: time="2025-02-21T10:35:37+07:00" level=info msg="Closing 2 connections to load balancer server master02:6443@STANDBY*"
Feb 21 10:35:37 worker02 rke2[5786]: time="2025-02-21T10:35:37+07:00" level=info msg="Server 172.31.46.103:6443@UNCHECKED->RECOVERING from successful health check"
Feb 21 10:35:37 worker02 rke2[5786]: time="2025-02-21T10:35:37+07:00" level=info msg="Server 172.31.35.122:9345@RECOVERING->PREFERRED from successful health check"
Feb 21 10:35:38 worker02 rke2[5786]: time="2025-02-21T10:35:38+07:00" level=info msg="Server 172.31.46.103:6443@RECOVERING->PREFERRED from successful health check" 
```

