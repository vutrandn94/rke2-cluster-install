# RKE2 Cluster Install (--proxy-mode=ipvs)
> [!TIP]
> Suitable for infrastructure >= 500 services

## Lab info (3 master, 3 worker)
| Hostname | IP Address | OS | Role | RKE Version |
| :--- | :--- | :--- | :--- | :--- |
| master01 | 172.31.44.224 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| master02 | 172.31.42.98 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| master03 | 172.31.46.130 | Ubuntu 22.04.5 LTS | master | v1.29.13+rke2r1 |
| worker01 | 172.31.38.182 | Ubuntu 22.04.5 LTS | worker | v1.29.13+rke2r1 |
| worker02 | 172.31.32.35 | Ubuntu 22.04.5 LTS | worker | v1.29.13+rke2r1 |
| worker03 | 172.31.41.123 | Ubuntu 22.04.5 LTS |worker | v1.29.13+rke2r1 |

*RKE2 Release version*: https://github.com/rancher/rke2/releases
## Config hosts file on all nodes (master & worker)
```
# cat /etc/hosts
---
## K8S MASTER 
172.31.44.224 master01 
172.31.42.98 master02 
172.31.46.130 master03 

## K8S WORKER
172.31.38.182 worker01 
172.31.32.35 worker02 
172.31.41.123 worker03 
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
**Instal IPVS package**
```
# apt install ipset ipvsadm -y
# vi /etc/modules-load.d/ipvs.conf
---
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
```
```
# systemctl restart systemd-modules-load
# systemctl status systemd-modules-load
# lsmod | grep ip_vs
ip_vs_sh               12288  0
ip_vs_wrr              12288  0
ip_vs_rr               12288  20
ip_vs                 225280  26 ip_vs_rr,ip_vs_sh,ip_vs_wrr
nf_conntrack          196608  5 xt_conntrack,nf_nat,nf_conntrack_netlink,xt_MASQUERADE,ip_vs
nf_defrag_ipv6         24576  2 nf_conntrack,ip_vs
libcrc32c              12288  4 nf_conntrack,nf_nat,nf_tables,ip_vs
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
**Instal IPVS package**
```
# apt install ipset ipvsadm -y
# vi /etc/modules-load.d/ipvs.conf
---
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
```
```
# systemctl restart systemd-modules-load
# systemctl status systemd-modules-load
# lsmod | grep ip_vs
ip_vs_sh               12288  0
ip_vs_wrr              12288  0
ip_vs_rr               12288  20
ip_vs                 225280  26 ip_vs_rr,ip_vs_sh,ip_vs_wrr
nf_conntrack          196608  5 xt_conntrack,nf_nat,nf_conntrack_netlink,xt_MASQUERADE,ip_vs
nf_defrag_ipv6         24576  2 nf_conntrack,ip_vs
libcrc32c              12288  4 nf_conntrack,nf_nat,nf_tables,ip_vs
```
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
kube-proxy-arg:
  - "proxy-mode=ipvs"
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
rke2-server.service - Rancher Kubernetes Engine v2 (server)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2025-08-15 08:49:19 UTC; 5min ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 3475 (rke2)
      Tasks: 162
     Memory: 2.2G
        CPU: 2min 33.586s
     CGroup: /system.slice/rke2-server.service
             ├─3475 "/usr/local/bin/rke2 server"
             ├─3493 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/agent/containerd
             ├─3505 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --anonymous-auth=false --authentication-token-webhook=true --aut>
             ├─3551 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 52207b515ec7ce0592e1da077688904e87504a2235fc9b0814a39b1ae01aef2a -address /run/k3s>
             ├─3560 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 8c220dc9b455e7bcc66cc43380bdf8d90264012ec13a643edbe292bee52971d9 -address /run/k3s>
             ├─3712 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id badda4cc5eed568c14812830b6d7fb324148782a27c176d2724569f277db4787 -address /run/k3s>
             ├─3806 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 096cdeb6b5b97aabc16276129a75261f584fdb766d9e9780efc0af91841c8c68 -address /run/k3s>
             ├─3885 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 2e821d74a77cd5e10259a4f299ba2b0d46bd5f37023e0a7236868453ff6d0342 -address /run/k3s>
             ├─4003 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 414c9133d4b1399999a486a00c8a58e11dfed5393c4dd03f5f8a8196941b5e29 -address /run/k3s>
             ├─5289 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 5b66fc555fededbcbe8c51c276563633d24f31d16f24c938a5360739aac73e97 -address /run/k3s>
             ├─5604 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id b2c6f498990dc5fb528cb3bd678d4d2e569dadd6e9bd270c60b86adef6323649 -address /run/k3s>
             ├─7211 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 7bef2b4b96d672695ba6a251fc03f6a3ad451e5a085591a79e2c1ecfd230edf1 -address /run/k3s>
             └─7239 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 28d2e4a167fb15de5dad0a1cfcc4f2bd2fed6bac40de07c6ebacfccb0e5dd2b7 -address /run/k3s>

Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Labels and annotations have been set successfully on node: master01"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Started tunnel to 172.31.44.224:9345"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Stopped tunnel to 127.0.0.1:9345"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Connecting to proxy" url="wss://172.31.44.224:9345/v1-rke2/connect"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Proxy done" err="context canceled" url="wss://127.0.0.1:9345/v1-rke2/connect"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="error in remotedialer server [400]: websocket: close 1006 (abnormal closure): unexpected EOF"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Handling backend connection request [master01]"
Aug 15 08:49:21 master01 rke2[3475]: time="2025-08-15T08:49:21Z" level=info msg="Remotedialer connected to proxy" url="wss://172.31.44.224:9345/v1-rke2/connect"
Aug 15 08:49:25 master01 rke2[3475]: time="2025-08-15T08:49:25Z" level=info msg="Adding node master01-38916c5b etcd status condition"
Aug 15 08:50:21 master01 rke2[3475]: time="2025-08-15T08:50:21Z" level=info msg="Tunnel authorizer set Kubelet Port 0.0.0.0:10250"
```


**Check k8s core kube-system container created**
```
# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                       ATTEMPT             POD ID              POD
4c9b39d34f11a       48e9296167c66       4 minutes ago       Running             coredns                    0                   28d2e4a167fb1       rke2-coredns-rke2-coredns-58664888cf-g255g
1ee40a2d15e15       6331715a2ae96       4 minutes ago       Running             calico-kube-controllers    0                   7bef2b4b96d67       calico-kube-controllers-57485788b5-5txj8
c4c5ea1522cf1       feb26d4585d68       4 minutes ago       Running             calico-node                0                   b2c6f498990dc       calico-node-wvlkn
437192605a8d0       3045aa4a360d4       4 minutes ago       Running             tigera-operator            0                   5b66fc555fede       tigera-operator-5d7c4bffdc-2tfkj
388fed13457db       46c32f22a3528       5 minutes ago       Running             kube-scheduler             0                   414c9133d4b13       kube-scheduler-master01
896e653fc5127       f8c22287de5e5       5 minutes ago       Running             cloud-controller-manager   0                   2e821d74a77cd       cloud-controller-manager-master01
a32e3899380e8       46c32f22a3528       5 minutes ago       Running             kube-controller-manager    0                   096cdeb6b5b97       kube-controller-manager-master01
7e24eb4de9c2c       46c32f22a3528       5 minutes ago       Running             kube-apiserver             0                   badda4cc5eed5       kube-apiserver-master01
f91e296148f35       05ee3fcb86374       6 minutes ago       Running             etcd                       0                   8c220dc9b455e       etcd-master01
7d23e3bf38fad       46c32f22a3528       6 minutes ago       Running             kube-proxy                 0                   52207b515ec7c       kube-proxy-master01
```

**Check IVPS route table**
```
# ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  ip-10-45-0-1.ap-southeast-1. rr
  -> master01:6443                Masq    1      5          19        
TCP  ip-10-45-0-10.ap-southeast-1 rr
  -> ip-10-44-241-66.ap-southeast Masq    1      0          0         
TCP  ip-10-45-31-132.ap-southeast rr
UDP  ip-10-45-0-10.ap-southeast-1 rr
  -> ip-10-44-241-66.ap-southeast Masq    1      0          0
```

**Copy kubeconfig context to "~/.kube"**
```
# cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
```

**Copy node token to join master & worker node to K8S cluster**
```
# cat /var/lib/rancher/rke2/server/node-token 
K10d2c0a9d96f1a935b75d001842a1d0e90edd8c6adb3da04db3137b07cea5f8d5e::server:bc3e3c0a19b417ad606261383ece0762
```

## Config  in remaining master nodes (master02, master03, ...)
*"server" value is "https://<HOSTNAME_NODE_MASTER01>:9345"*

*"token" value is node token copied in above*

**Define "config.yaml" file**
```
# vi/etc/rancher/rke2/config.yaml
---
server: "https://master01:9345"
token: "K10d2c0a9d96f1a935b75d001842a1d0e90edd8c6adb3da04db3137b07cea5f8d5e::server:bc3e3c0a19b417ad606261383ece0762"
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
kube-proxy-arg:
  - "proxy-mode=ipvs"
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
     Active: active (running) since Fri 2025-08-15 09:03:14 UTC; 1min 41s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 1748 (rke2)
      Tasks: 122
     Memory: 2.3G
        CPU: 2min 1.270s
     CGroup: /system.slice/rke2-server.service
             ├─1748 "/usr/local/bin/rke2 server"
             ├─1763 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/agent/containerd
             ├─1774 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --anonymous-auth=false --authentication-token-webhook=true --aut>
             ├─1820 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id cd9c4e5e37c40d044652109524a4b032cfd4f1fd608507b3c8e2c0c236a5043d -address /run/k3s>
             ├─1821 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id df679ebffb0fd4c5fbbcffef8e2020482aab8893bb3ae72abcc530a724ed939a -address /run/k3s>
             ├─1984 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 95a77f245afc8cce59038f306ac0a1684dd19c81a9814fe04937a556400e1d26 -address /run/k3s>
             ├─2316 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id d73cda1926270edac628499ee10b4d629139b356b2f5e8fa800ee4938d9acee3 -address /run/k3s>
             ├─2341 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id c8ad5a5a36db06d3a3d2745974c3a9c038dc8ef6c9924b9f53fdee75d5fbb7e6 -address /run/k3s>
             ├─2344 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 97d0b6f37db6988d5bb8076dc1530253f43327aacbcb3cb8df269e5ddea9ad71 -address /run/k3s>
             └─3336 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 1869ebb6bb30f71bcca0d0fc3f151027a534f0f0addada785a3f8e7b7d1cf18f -address /run/k3s>

Aug 15 09:03:15 master02 rke2[1748]: time="2025-08-15T09:03:15Z" level=info msg="Creating deploy event broadcaster"
Aug 15 09:03:15 master02 rke2[1748]: time="2025-08-15T09:03:15Z" level=info msg="Starting /v1, Kind=Node controller"
Aug 15 09:03:15 master02 rke2[1748]: time="2025-08-15T09:03:15Z" level=info msg="Cluster dns configmap already exists"
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="certificate CN=rke2,O=rke2 signed by CN=rke2-server-ca@1755247672: notBefore=2025-08-15 08:47:52 +0000 UTC notAfter=2026-08-15 >
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="Updating TLS secret for kube-system/rke2-serving (count: 13): map[listener.cattle.io/cn-10.45.0.1:10.45.0.1 listener.cattle.io/>
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="Starting /v1, Kind=Secret controller"
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="Updating TLS secret for kube-system/rke2-serving (count: 13): map[listener.cattle.io/cn-10.45.0.1:10.45.0.1 listener.cattle.io/>
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="Active TLS secret kube-system/rke2-serving (ver=3799) (count 13): map[listener.cattle.io/cn-10.45.0.1:10.45.0.1 listener.cattle>
Aug 15 09:03:16 master02 rke2[1748]: time="2025-08-15T09:03:16Z" level=info msg="Labels and annotations have been set successfully on node: master02"
Aug 15 09:03:56 master02 rke2[1748]: time="2025-08-15T09:03:56Z" level=info msg="Tunnel authorizer set Kubelet Port 0.0.0.0:10250"
```
**Check k8s core kube-system container created**
```
# crictl ps
CONTAINER           IMAGE               CREATED              STATE               NAME                       ATTEMPT             POD ID              POD
0071f690f1451       feb26d4585d68       About a minute ago   Running             calico-node                0                   1869ebb6bb30f       calico-node-xxczn
cabca555c66a3       f8c22287de5e5       2 minutes ago        Running             cloud-controller-manager   0                   97d0b6f37db69       cloud-controller-manager-master02
8add650e97175       46c32f22a3528       2 minutes ago        Running             kube-scheduler             0                   c8ad5a5a36db0       kube-scheduler-master02
8817334243d8b       46c32f22a3528       2 minutes ago        Running             kube-controller-manager    0                   d73cda1926270       kube-controller-manager-master02
fb88dc1b3dab6       46c32f22a3528       2 minutes ago        Running             kube-apiserver             0                   95a77f245afc8       kube-apiserver-master02
c431cf24d7865       05ee3fcb86374       2 minutes ago        Running             etcd                       0                   cd9c4e5e37c40       etcd-master02
d951a319510d8       46c32f22a3528       2 minutes ago        Running             kube-proxy                 0                   df679ebffb0fd       kube-proxy-master02
```

**Copy kubeconfig context to "~/.kube"**
```
# cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
```


## Config and join worker nodes (worker01, worker02, worker03,...)
**Define "config.yaml" file**
*"server" value is "https://<HOSTNAME_NODE_MASTER01>:9345"*

*"token" value is node token copied in above*

```
# vi /etc/rancher/rke2/config.yaml
---
server: "https://master01:9345"
token: "K10d2c0a9d96f1a935b75d001842a1d0e90edd8c6adb3da04db3137b07cea5f8d5e::server:bc3e3c0a19b417ad606261383ece0762"
node-label:
  - "node.kubernetes.io/role=worker"
kube-proxy-arg:
  - "proxy-mode=ipvs"
```

**Start & enable rke2-agent systemd service**
```
# systemctl start rke2-agent && systemctl enable rke2-agent
```
```
# systemctl status rke2-agent
● rke2-agent.service - Rancher Kubernetes Engine v2 (agent)
     Loaded: loaded (/usr/local/lib/systemd/system/rke2-agent.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2025-08-15 09:28:04 UTC; 11s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 1767 (rke2)
      Tasks: 52
     Memory: 1.2G
        CPU: 15.404s
     CGroup: /system.slice/rke2-agent.service
             ├─1767 "/usr/local/bin/rke2 agent"
             ├─1781 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/agent/containerd
             ├─1791 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --allowed-unsafe-sysctls=net.ipv4.ip_forward,net.ipv6.conf.all.f>
             ├─1932 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id f7b8946be6ecf6312a6ebcc17d32f7c1b6798882ebefa62bf884cab213058ae0 -address /run/k3s>
             └─1935 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id f21525fb08cc879ea121992af1e2bdfc3df8272fe2b3a8bfca4c5414ede1da8b -address /run/k3s>

Aug 15 09:28:04 worker01 rke2[1767]: time="2025-08-15T09:28:04Z" level=info msg="Server 172.31.42.98:6443@RECOVERING->ACTIVE from successful health check"
Aug 15 09:28:04 worker01 rke2[1767]: time="2025-08-15T09:28:04Z" level=info msg="Closing 1 connections to load balancer server master01:6443@STANDBY*"
Aug 15 09:28:04 worker01 rke2[1767]: time="2025-08-15T09:28:04Z" level=info msg="Server 172.31.44.224:6443@UNCHECKED->RECOVERING from successful health check"
Aug 15 09:28:04 worker01 rke2[1767]: time="2025-08-15T09:28:04Z" level=info msg="Server 172.31.46.130:6443@UNCHECKED->RECOVERING from successful health check"
Aug 15 09:28:05 worker01 rke2[1767]: time="2025-08-15T09:28:05Z" level=info msg="Server 172.31.46.130:9345@RECOVERING->PREFERRED from successful health check"
Aug 15 09:28:05 worker01 rke2[1767]: time="2025-08-15T09:28:05Z" level=info msg="Server 172.31.42.98:9345@RECOVERING->PREFERRED from successful health check"
Aug 15 09:28:05 worker01 rke2[1767]: time="2025-08-15T09:28:05Z" level=info msg="Server 172.31.44.224:6443@RECOVERING->PREFERRED from successful health check"
Aug 15 09:28:05 worker01 rke2[1767]: time="2025-08-15T09:28:05Z" level=info msg="Server 172.31.46.130:6443@RECOVERING->PREFERRED from successful health check"
Aug 15 09:28:06 worker01 rke2[1767]: time="2025-08-15T09:28:06Z" level=info msg="Pulling images from /var/lib/rancher/rke2/agent/images/kube-proxy-image.txt"
Aug 15 09:28:06 worker01 rke2[1767]: time="2025-08-15T09:28:06Z" level=info msg="Pulling image index.docker.io/rancher/hardened-kubernetes:v1.29.13-rke2r1-build20250117"
```

**Check IVPS route table**
```
# ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  ip-10-45-0-1.ap-southeast-1. rr
  -> master02:6443                Masq    1      2          4         
  -> master01:6443                Masq    1      2          4         
  -> master03:6443                Masq    1      1          4         
TCP  ip-10-45-0-10.ap-southeast-1 rr
  -> ip-10-44-241-66.ap-southeast Masq    1      0          0         
TCP  ip-10-45-31-132.ap-southeast rr
  -> worker01:5473                Masq    1      0          0         
UDP  ip-10-45-0-10.ap-southeast-1 rr
  -> ip-10-44-241-66.ap-southeast Masq    1      0          0    
```

## Verify cluster state (Run command on master nodes)
**Check cluster state**
```
root@master01:~# kubectl get node
NAME       STATUS   ROLES                       AGE     VERSION
master01   Ready    control-plane,etcd,master   58m     v1.29.13+rke2r1
master02   Ready    control-plane,etcd,master   44m     v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   30m     v1.29.13+rke2r1
worker01   Ready    <none>                      19m     v1.29.13+rke2r1
worker02   Ready    <none>                      4m19s   v1.29.13+rke2r1
worker03   Ready    <none>                      52s     v1.29.13+rke2r1
```
```
root@master01:~# kubectl get pod -n  kube-system
NAME                                                    READY   STATUS      RESTARTS   AGE
cloud-controller-manager-master01                       1/1     Running     0          58m
cloud-controller-manager-master02                       1/1     Running     0          44m
cloud-controller-manager-master03                       1/1     Running     0          29m
etcd-master01                                           1/1     Running     0          58m
etcd-master02                                           1/1     Running     0          44m
etcd-master03                                           1/1     Running     0          29m
helm-install-rke2-calico-9bj7h                          0/1     Completed   2          58m
helm-install-rke2-calico-crd-pc9mt                      0/1     Completed   0          58m
helm-install-rke2-coredns-vbnx7                         0/1     Completed   0          58m
helm-install-rke2-metrics-server-l29jz                  0/1     Completed   0          58m
helm-install-rke2-runtimeclasses-4bvt4                  0/1     Completed   0          58m
helm-install-rke2-snapshot-controller-crd-bl2cl         0/1     Completed   0          58m
helm-install-rke2-snapshot-controller-w5npv             0/1     Completed   1          58m
kube-apiserver-master01                                 1/1     Running     0          58m
kube-apiserver-master02                                 1/1     Running     0          44m
kube-apiserver-master03                                 1/1     Running     0          30m
kube-controller-manager-master01                        1/1     Running     0          58m
kube-controller-manager-master02                        1/1     Running     0          44m
kube-controller-manager-master03                        1/1     Running     0          30m
kube-proxy-master01                                     1/1     Running     0          58m
kube-proxy-master02                                     1/1     Running     0          44m
kube-proxy-master03                                     1/1     Running     0          30m
kube-proxy-worker01                                     1/1     Running     0          19m
kube-proxy-worker02                                     1/1     Running     0          4m32s
kube-proxy-worker03                                     1/1     Running     0          66s
kube-scheduler-master01                                 1/1     Running     0          58m
kube-scheduler-master02                                 1/1     Running     0          44m
kube-scheduler-master03                                 1/1     Running     0          30m
rke2-coredns-rke2-coredns-58664888cf-g255g              1/1     Running     0          58m
rke2-coredns-rke2-coredns-58664888cf-qqwkn              1/1     Running     0          18m
rke2-coredns-rke2-coredns-autoscaler-7dfbb46d5d-xz62z   1/1     Running     0          58m
rke2-metrics-server-8599b78c6d-74tnx                    1/1     Running     0          18m
rke2-snapshot-controller-55d765465-4lbmr                1/1     Running     0          18m
```
**Check etcd cluster state**
```
root@master01:~# kubectl exec -it etcd-master01 -n kube-system -- etcdctl --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key --endpoints=https://127.0.0.1:2379 endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 7.952557ms


root@master01:~# kubectl exec -it etcd-master01 -n kube-system -- etcdctl --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key --endpoints=https://127.0.0.1:2379 member list
81bfaeaf474d1df, started, master02-33181a3f, https://172.31.42.98:2380, https://172.31.42.98:2379, false
b84529ebe2383786, started, master01-38916c5b, https://172.31.44.224:2380, https://172.31.44.224:2379, false
cd902eb269759178, started, master03-760a8fe2, https://172.31.46.130:2380, https://172.31.46.130:2379, false
```

**Set roles for worker nodes**
```
root@master01:~# kubectl label node worker01 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl label node worker02 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl label node worker03 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl get nodes -o wide
NAME       STATUS   ROLES                       AGE     VERSION           INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
master01   Ready    control-plane,etcd,master   60m     v1.29.13+rke2r1   172.31.44.224   <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
master02   Ready    control-plane,etcd,master   46m     v1.29.13+rke2r1   172.31.42.98    <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
master03   Ready    control-plane,etcd,master   32m     v1.29.13+rke2r1   172.31.46.130   <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
worker01   Ready    worker                      21m     v1.29.13+rke2r1   172.31.38.182   <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
worker02   Ready    worker                      6m8s    v1.29.13+rke2r1   172.31.32.35    <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
worker03   Ready    worker                      2m41s   v1.29.13+rke2r1   172.31.41.123   <none>        Ubuntu 22.04.5 LTS   6.8.0-1029-aws   containerd://1.7.23-k3s2
```
