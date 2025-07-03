# RKE2 Cluster Install
## Lab info (3 master, 3 worker)
| Hostname | IP Address | OS | Role | RKE Version |
| :--- | :--- | :--- | :--- | :--- |
| master01 | 172.31.37.244 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| master02 | 172.31.46.103 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| master03 | 172.31.35.122 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| worker01 | 172.31.39.156 | Ubuntu 22.04.5 LTS | worker | v1.29.13+rke2r1 |
| worker02 | 172.31.33.71 | Ubuntu 22.04.5 LTS | worker | v1.29.13+rke2r1 |
| worker03 | 172.31.47.81 | Ubuntu 22.04.5 LTS |worker | v1.29.13+rke2r1 |

*RKE2 Release version*: https://github.com/rancher/rke2/releases
## Config hosts file on all nodes (master & worker)
```
# cat /etc/hosts
---
## K8S MASTER 
172.31.37.244 master01 
172.31.46.103 master02 
172.31.35.122 master03 

## K8S WORKER
172.31.39.156 worker01 
172.31.33.71 worker02 
172.31.47.81 worker03 
```
## Install & pre-config on all master nodes
**Config sysctl.conf**
```
# vi /etc/sysctl.conf
---
net.ipv4.ip_forward=1
kernel.randomize_va_space=2
fs.suid_dumpable=0
kernel.keys.root_maxbytes=25000000
kernel.keys.root_maxkeys=1000000
kernel.panic=10
kernel.panic_on_oops=1
vm.overcommit_memory=1
vm.panic_on_oom=0
net.ipv4.ip_local_reserved_ports=30000-32767
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-arptables=1
net.bridge.bridge-nf-call-ip6tables=1

# sysctl -p
```
**Install RKE2 software package**
```
# curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="v1.29.13+rke2r1" sh -
# mkdir -p /etc/rancher/rke2 ~/.kube
```
**Install crictl**
```
# VERSION="v1.30.0"
# wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
# sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
# rm -f crictl-$VERSION-linux-amd64.tar.gz
# vi /etc/crictl.yaml
---
runtime-endpoint: unix:///var/run/k3s/containerd/containerd.sock
image-endpoint: unix:///var/run/k3s/containerd/containerd.sock
timeout: 10
debug: false

```

**Install kubectl**
```
# curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
# curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256
# echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

```

**Install helm**
```
# curl -fsSL -o /usr/local/src/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod +x /usr/local/src/get_helm.sh
# /usr/local/src/get_helm.sh

```

## Install & pre-config on all worker nodes
**Install RKE2 software package**
```
# curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="v1.29.13+rke2r1" sh -
# mkdir -p /etc/rancher/rke2

```
**Install crictl**
```
# VERSION="v1.30.0"
# wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
# sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
# rm -f crictl-$VERSION-linux-amd64.tar.gz
# vi /etc/crictl.yaml
---
runtime-endpoint: unix:///var/run/k3s/containerd/containerd.sock
image-endpoint: unix:///var/run/k3s/containerd/containerd.sock
timeout: 10
debug: false

```

## Config in node "master01" (RKE2 server)
**Define "config.yaml" file**
```
# vi /etc/rancher/rke2/config.yaml
---
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
```
**Start & enable rke2-server systemd service**
```
# systemctl start rke2-server && systemctl enable rke2-server
```

**Check process bootrap cluster in 1 other session**
```
# journalctl -f -u rke2-server
```
```
# systemctl status rke2-server
● rke2-server.service - Rancher Kubernetes Engine v2 (server)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-02-20 14:26:25 +07; 3min 20s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 3814 (rke2)
      Tasks: 161
     Memory: 2.4G
        CPU: 2min 58.720s
     CGroup: /system.slice/rke2-server.service
             ├─3814 "/usr/local/bin/rke2 server"
             ├─3830 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/age>             ├─3910 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --anonymous-auth=false --authentication-toke>             ├─3956 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 721013ef8f29bbb22f44c65b3b170010e557a3edc7d61c527068a702734af1>             ├─3967 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 068a1e96f2ac9a23d6451cf18e248f713fcea4b9e08804149354cb116b0f64>             ├─4116 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 4305749985cc98d3cff01d8390883aedee03fe9c2fef4c5ab02219fd106e33>             ├─4199 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id c69bc2906e6b83d6d25873f66775358f5261a1ff03e8d90efb3667f447d950>             ├─4283 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id b5661d191dab99bc28b38cbae355018227a21c5d254598dc3718a95b519658>             ├─4528 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 9a0308bcd1d4e33b39fe35444416cb9078248dba893e69d410675c30bd39d9>             ├─5518 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 8222c4ee4f1ce3bc98ac537aab93a0b99e38a8cf3ab1afc85fe98fca62e64e>             ├─5718 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id c19b368803d26a70c59cffaafcc3d94822c680a39b80f14623f6279b2e1c88>             ├─7155 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 30aa8f2de4590d39bbc674c20e45aaaae02d4b639d2f188055fe5c6d24227e>             └─7168 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id aa048e01cdd0c3862008f0ae6b4a320b8dfe4be53b2ce97e9993f15c92fdab>
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Started tunnel to 172.31.37.244:9345"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Stopped tunnel to 127.0.0.1:9345"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Connecting to proxy" url="wss://172.31.37.244:9345/v1-rke2/connect"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Proxy done" err="context canceled" url="wss://127.0.0.1:9345/v1-rke2/connect"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="error in remotedialer server [400]: websocket: close 1006 (abnormal closure): unexpected EOF"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Handling backend connection request [master01]"
Feb 20 14:26:26 master01 rke2[3814]: time="2025-02-20T14:26:26+07:00" level=info msg="Remotedialer connected to proxy" url="wss://172.31.37.244:9345/v1-rke2/connect"
Feb 20 14:26:27 master01 rke2[3814]: time="2025-02-20T14:26:27+07:00" level=info msg="Labels and annotations have been set successfully on node: master01"
Feb 20 14:26:30 master01 rke2[3814]: time="2025-02-20T14:26:30+07:00" level=info msg="Adding node master01-5c63c9d8 etcd status condition"
Feb 20 14:27:30 master01 rke2[3814]: time="2025-02-20T14:27:30+07:00" level=info msg="Tunnel authorizer set Kubelet Port 0.0.0.0:10250"
```


**Check k8s core kube-system container created**
```
# crictl ps
CONTAINER           IMAGE               CREATED              STATE               NAME                       ATTEMPT             POD ID              POD
4b62c8daff63c       3045aa4a360d4       24 seconds ago       Running             tigera-operator            0                   8222c4ee4f1ce       tigera-operator-5d7c4bffdc-9kvcr
4c3b362247f6b       46c32f22a3528       About a minute ago   Running             kube-scheduler             0                   9a0308bcd1d4e       kube-scheduler-master01
e0a026032bd4c       f8c22287de5e5       About a minute ago   Running             cloud-controller-manager   0                   b5661d191dab9       cloud-controller-manager-master01
59133bdc9704c       46c32f22a3528       About a minute ago   Running             kube-controller-manager    0                   c69bc2906e6b8       kube-controller-manager-master01
442ccbba1c6e2       46c32f22a3528       About a minute ago   Running             kube-apiserver             0                   4305749985cc9       kube-apiserver-master01
f5ce7070a7749       05ee3fcb86374       About a minute ago   Running             etcd                       0                   068a1e96f2ac9       etcd-master01
437b27d3e2e90       46c32f22a3528       About a minute ago   Running             kube-proxy                 0                   721013ef8f29b       kube-proxy-master01
```

**Copy kubeconfig context to "~/.kube"**
```
# cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
```

**Copy node token to join master & worker node to K8S cluster**
```
# cat /var/lib/rancher/rke2/server/node-token 
K10db22ba60f121623903839d71f7ad604b05b08ef2dda6d68b7034104aa308d951::server:d1f9805b444aede79f8abb0e85cda6df
```

## Config  in remaining master nodes (master02, master03, ...)
*"server" value is "https://<HOSTNAME_NODE_MASTER01>:9345"*

*"token" value is node token copied in above*

**Define "config.yaml" file**
```
# vi/etc/rancher/rke2/config.yaml
---
server: "https://master01:9345"
token: "K10db22ba60f121623903839d71f7ad604b05b08ef2dda6d68b7034104aa308d951::server:d1f9805b444aede79f8abb0e85cda6df"
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
```
**Start & enable rke2-server systemd service**
```
# systemctl start rke2-server && systemctl enable rke2-server
```
**Check process bootrap cluster in 1 other session**
```
# journalctl -f -u rke2-server
```
```
# systemctl status rke2-server
● rke2-server.service - Rancher Kubernetes Engine v2 (server)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-02-20 14:42:24 +07; 12s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 3842 (rke2)
      Tasks: 108
     Memory: 2.0G
        CPU: 1min 51.490s
     CGroup: /system.slice/rke2-server.service
             ├─3842 "/usr/local/bin/rke2 server"
             ├─3859 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/age>             ├─3870 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --anonymous-auth=false --authentication-toke>             ├─3916 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id c28c56a5581b0c2ee978325c1ab3b6652fdfdcd7ef139462a6122e7bd6d58f>             ├─3934 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 07dd6e3961c06d3d0d81d48c8ec723bc97f957be483485b75ae219d0d4b64f>             ├─4079 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id c50a239b615c5002adf114deed7c962924da4b877b99ddaaee301f108a90f7>             ├─4357 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id eb50d35ea06030e45cf4350641c7bdb5ed7327159430ae5161f73c6c116069>             ├─4383 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id f958a7b53f66bb64947eabb60dfb4036935ccc2a1be28bb7de17dcde9ff6b5>             └─4392 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id b59d928ba26e251f7b1f52c744f6860837e33e4ce609f8692382581d675f62>
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Creating deploy event broadcaster"
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Reconciliation of ETCDSnapshotFile resources complete"
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Starting /v1, Kind=Node controller"
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Cluster dns configmap already exists"
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="certificate CN=rke2,O=rke2 signed by CN=rke2-server-ca@1740036267: notBefore=2025-02-20 07:24:27 +0000>Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Updating TLS secret for kube-system/rke2-serving (count: 13): map[listener.cattle.io/cn-10.45.0.1:10.4>Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Starting /v1, Kind=Secret controller"
Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Updating TLS secret for kube-system/rke2-serving (count: 13): map[listener.cattle.io/cn-10.45.0.1:10.4>Feb 20 14:42:24 master02 rke2[3842]: time="2025-02-20T14:42:24+07:00" level=info msg="Active TLS secret kube-system/rke2-serving (ver=4204) (count 13): map[listener.cattle.io/cn-10.45.0.1:>Feb 20 14:42:25 master02 rke2[3842]: time="2025-02-20T14:42:25+07:00" level=info msg="Labels and annotations have been set successfully on node: master02"
```
**Check k8s core kube-system container created**
```
# crictl ps
CONTAINER           IMAGE               CREATED              STATE               NAME                       ATTEMPT             POD ID              POD
eedc86ab605e7       f8c22287de5e5       56 seconds ago       Running             cloud-controller-manager   0                   b59d928ba26e2       cloud-controller-manager-master02
9f1a0318de374       46c32f22a3528       56 seconds ago       Running             kube-scheduler             0                   f958a7b53f66b       kube-scheduler-master02
d4cabf25644f3       46c32f22a3528       56 seconds ago       Running             kube-controller-manager    0                   eb50d35ea0603       kube-controller-manager-master02
f5508b9e434ab       46c32f22a3528       About a minute ago   Running             kube-apiserver             0                   c50a239b615c5       kube-apiserver-master02
dcdf17faa5a87       05ee3fcb86374       About a minute ago   Running             etcd                       0                   c28c56a5581b0       etcd-master02
33595b8df041b       46c32f22a3528       About a minute ago   Running             kube-proxy                 0                   07dd6e3961c06       kube-proxy-master02
```

**Copy kubeconfig context to "~/.kube"**
```
# cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
```


## Config and join worker nodes (worker01, worker02, worker03,...)
**Config sysctl.conf**
```
# vi /etc/sysctl.conf
---
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

# sysctl -p
```
**Define "config.yaml" file**
*"server" value is "https://<HOSTNAME_NODE_MASTER01>:9345"*

*"token" value is node token copied in above*

```
# vi/etc/rancher/rke2/config.yaml
---
server: "https://master01:9345"
token: "K10db22ba60f121623903839d71f7ad604b05b08ef2dda6d68b7034104aa308d951::server:d1f9805b444aede79f8abb0e85cda6df"
node-label:
  - "node.kubernetes.io/role=worker"
```

**Start & enable rke2-agent systemd service**
```
# systemctl start rke2-agent && systemctl enable rke2-agent
```
```
# systemctl status rke2-agent
● rke2-agent.service - Rancher Kubernetes Engine v2 (agent)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-agent.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-02-20 14:56:47 +07; 37s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 3497 (rke2)
      Tasks: 79
     Memory: 2.4G
        CPU: 32.055s
     CGroup: /system.slice/rke2-agent.service
             ├─3497 "/usr/local/bin/rke2 agent"
             ├─3511 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/age>             ├─3520 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --allowed-unsafe-sysctls=net.ipv4.ip_forward>             ├─3596 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 9a166c708fa694c3a9dacceb80e8ec13231ad64584a693a48adc1351713eb9>             ├─3609 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id fad97b295c54f391e7d65b98fa0638d3bf4739f2c8b07c16d2625d609043c4>             └─4085 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id faa531c8b5bb08459a4c7dc8818f4c43349d37474f4e9b25aca3f5ba200b76>
Feb 20 14:56:47 worker01 rke2[3497]: time="2025-02-20T14:56:47+07:00" level=info msg="Server 172.31.46.103:9345@UNCHECKED->RECOVERING from successful health check"
Feb 20 14:56:48 worker01 rke2[3497]: time="2025-02-20T14:56:48+07:00" level=info msg="Server 172.31.37.244:6443@RECOVERING->PREFERRED from successful health check"
Feb 20 14:56:48 worker01 rke2[3497]: time="2025-02-20T14:56:48+07:00" level=info msg="Server 172.31.46.103:6443@RECOVERING->PREFERRED from successful health check"
Feb 20 14:56:48 worker01 rke2[3497]: time="2025-02-20T14:56:48+07:00" level=info msg="Server 172.31.37.244:9345@RECOVERING->PREFERRED from successful health check"
Feb 20 14:56:48 worker01 rke2[3497]: time="2025-02-20T14:56:48+07:00" level=info msg="Server 172.31.46.103:9345@RECOVERING->PREFERRED from successful health check"
Feb 20 14:56:49 worker01 rke2[3497]: time="2025-02-20T14:56:49+07:00" level=info msg="Pulling images from /var/lib/rancher/rke2/agent/images/kube-proxy-image.txt"
Feb 20 14:56:49 worker01 rke2[3497]: time="2025-02-20T14:56:49+07:00" level=info msg="Pulling image index.docker.io/rancher/hardened-kubernetes:v1.29.13-rke2r1-build20250117"
Feb 20 14:57:04 worker01 rke2[3497]: time="2025-02-20T14:57:04+07:00" level=error msg="Failed to import /var/lib/rancher/rke2/agent/images/kube-proxy-image.txt: failed to pull images from >Feb 20 14:57:04 worker01 rke2[3497]: time="2025-02-20T14:57:04+07:00" level=error msg="Failed to process image event: failed to pull images from /var/lib/rancher/rke2/agent/images/kube-pro>Feb 20 14:57:11 worker01 rke2[3497]: time="2025-02-20T14:57:11+07:00" level=info msg="Tunnel authorizer set Kubelet Port 0.0.0.0:10250"
```

## Verify cluster state (Run command on master nodes)
**Check cluster state**
```
root@master01:~# kubectl get node
NAME       STATUS   ROLES                       AGE     VERSION
master01   Ready    control-plane,etcd,master   51m     v1.29.13+rke2r1
master02   Ready    control-plane,etcd,master   35m     v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   27m     v1.29.13+rke2r1
worker01   Ready    <none>                      21m     v1.29.13+rke2r1
worker02   Ready    <none>                      3m18s   v1.29.13+rke2r1
worker03   Ready    <none>                      99s     v1.29.13+rke2r1
```
```
root@master01:~# kubectl get pod -n  kube-system
NAME                                                    READY   STATUS      RESTARTS   AGE
cloud-controller-manager-master01                       1/1     Running     0          53m
cloud-controller-manager-master02                       1/1     Running     0          36m
cloud-controller-manager-master03                       1/1     Running     0          29m
etcd-master01                                           1/1     Running     0          53m
etcd-master02                                           1/1     Running     0          37m
etcd-master03                                           1/1     Running     0          29m
helm-install-rke2-calico-28cv6                          0/1     Completed   2          53m
helm-install-rke2-calico-crd-h6x5z                      0/1     Completed   0          53m
helm-install-rke2-coredns-qgsx7                         0/1     Completed   0          53m
helm-install-rke2-metrics-server-7kjsr                  0/1     Completed   0          53m
helm-install-rke2-runtimeclasses-5tl75                  0/1     Completed   0          53m
helm-install-rke2-snapshot-controller-5l4fv             0/1     Completed   1          53m
helm-install-rke2-snapshot-controller-crd-96gzl         0/1     Completed   0          53m
kube-apiserver-master01                                 1/1     Running     0          53m
kube-apiserver-master02                                 1/1     Running     0          37m
kube-apiserver-master03                                 1/1     Running     0          29m
kube-controller-manager-master01                        1/1     Running     0          53m
kube-controller-manager-master02                        1/1     Running     0          37m
kube-controller-manager-master03                        1/1     Running     0          29m
kube-proxy-master01                                     1/1     Running     0          53m
kube-proxy-master02                                     1/1     Running     0          36m
kube-proxy-master03                                     1/1     Running     0          29m
kube-proxy-worker01                                     1/1     Running     0          23m
kube-proxy-worker02                                     1/1     Running     0          5m33s
kube-proxy-worker03                                     1/1     Running     0          3m54s
kube-scheduler-master01                                 1/1     Running     0          53m
kube-scheduler-master02                                 1/1     Running     0          37m
kube-scheduler-master03                                 1/1     Running     0          29m
rke2-coredns-rke2-coredns-58664888cf-52tpm              1/1     Running     0          22m
rke2-coredns-rke2-coredns-58664888cf-lrxvd              1/1     Running     0          53m
rke2-coredns-rke2-coredns-autoscaler-7dfbb46d5d-pzfxg   1/1     Running     0          53m
rke2-metrics-server-8599b78c6d-b782w                    1/1     Running     0          22m
rke2-snapshot-controller-55d765465-24cs6                1/1     Running     0          22m
```
**Check etcd cluster state**
```
root@master01:~# kubectl exec -it etcd-master01 -n kube-system -- etcdctl --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key --endpoints=https://127.0.0.1:2379 endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 11.183476ms


root@master01:~# kubectl exec -it etcd-master01 -n kube-system -- etcdctl --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key --endpoints=https://127.0.0.1:2379 member list
2d1228ceaa1bd4d3, started, master01-5c63c9d8, https://172.31.37.244:2380, https://172.31.37.244:2379, false
3b513b2038db6df2, started, master03-c4ef7ee4, https://172.31.35.122:2380, https://172.31.35.122:2379, false
c0f37dd0944ffe4d, started, master02-505b9a7a, https://172.31.46.103:2380, https://172.31.46.103:2379, false
```

**Set roles for worker nodes**
```
root@master01:~# kubectl label node worker01 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl label node worker02 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl label node worker03 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl get nodes -o wide
NAME       STATUS   ROLES                       AGE     VERSION           INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
master01   Ready    control-plane,etcd,master   58m     v1.29.13+rke2r1   172.31.37.244   <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
master02   Ready    control-plane,etcd,master   42m     v1.29.13+rke2r1   172.31.46.103   <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
master03   Ready    control-plane,etcd,master   34m     v1.29.13+rke2r1   172.31.35.122   <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
worker01   Ready    worker                      27m     v1.29.13+rke2r1   172.31.39.156   <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
worker02   Ready    worker                      9m44s   v1.29.13+rke2r1   172.31.33.71    <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
worker03   Ready    worker                      8m5s    v1.29.13+rke2r1   172.31.47.81    <none>        Ubuntu 22.04.5 LTS   6.8.0-1021-aws   containerd://1.7.23-k3s2
```
