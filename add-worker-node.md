# Add Node to RKE2 Cluster
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
172.31.36.12 worker04
```

## Install & pre-config on new worker nodes
**Install RKE2 software package**
```
# curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="v1.29.13+rke2r1" sh -
# mkdir -p /etc/rancher/rke2

```
*Replace "INSTALL_RKE2_VERSION" with RKE2 release version installed*

*RKE2 Release version*: https://github.com/rancher/rke2/releases*

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

## Config and join worker nodes
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
**Define "config.yaml" file**
*"server" value is "https://<HOSTNAME_NODE_MASTER01>:9345"*

*"token" value is node token copied in /var/lib/rancher/rke2/server/node-token on master01*

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
     Active: active (running) since Thu 2025-02-20 15:57:22 +07; 10s ago
       Docs: https://github.com/rancher/rke2#readme
   Main PID: 3779 (rke2)
      Tasks: 50
     Memory: 1.1G
        CPU: 12.201s
     CGroup: /system.slice/rke2-agent.service
             ├─3779 "/usr/local/bin/rke2 agent"
             ├─3794 containerd -c /var/lib/rancher/rke2/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/rke2/age>             ├─3804 kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins --file-check-frequency=5s --sync-frequency=30s --address=0.0.0.0 --allowed-unsafe-sysctls=net.ipv4.ip_forward>             ├─3883 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id 50256f4996aad6025a489224a33e0f3b3f522fc27876f851005bbb7e49299e>             └─3884 /var/lib/rancher/rke2/data/v1.29.13-rke2r1-2082a73a5c4d/bin/containerd-shim-runc-v2 -namespace k8s.io -id d6a5b403452418138f323b79b16f33d0f9a790038adfda0301d90238a27727>
Feb 20 15:57:23 worker04 rke2[3779]: time="2025-02-20T15:57:23+07:00" level=info msg="Server 172.31.35.122:6443@UNCHECKED->RECOVERING from successful health check"
Feb 20 15:57:23 worker04 rke2[3779]: time="2025-02-20T15:57:23+07:00" level=info msg="Server 172.31.37.244:6443@UNCHECKED->RECOVERING from successful health check"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Server 172.31.35.122:9345@RECOVERING->PREFERRED from successful health check"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Server 172.31.37.244:9345@RECOVERING->PREFERRED from successful health check"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Server 172.31.35.122:6443@RECOVERING->PREFERRED from successful health check"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Server 172.31.37.244:6443@RECOVERING->PREFERRED from successful health check"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Server 172.31.46.103:9345@PREFERRED->ACTIVE from successful dial"
Feb 20 15:57:24 worker04 rke2[3779]: time="2025-02-20T15:57:24+07:00" level=info msg="Closing 1 connections to load balancer server master01:9345@STANDBY*"
Feb 20 15:57:25 worker04 rke2[3779]: time="2025-02-20T15:57:25+07:00" level=info msg="Pulling images from /var/lib/rancher/rke2/agent/images/kube-proxy-image.txt"
Feb 20 15:57:25 worker04 rke2[3779]: time="2025-02-20T15:57:25+07:00" level=info msg="Pulling image index.docker.io/rancher/hardened-kubernetes:v1.29.13-rke2r1-build20250117"
```

## Re-Verify cluster node (Run command on master nodes)
**Check cluster nodes**
```
root@master01:~# kubectl get nodes
NAME       STATUS   ROLES                       AGE    VERSION
master01   Ready    control-plane,etcd,master   92m    v1.29.13+rke2r1
master02   Ready    control-plane,etcd,master   76m    v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   68m    v1.29.13+rke2r1
worker01   Ready    worker                      62m    v1.29.13+rke2r1
worker02   Ready    worker                      44m    v1.29.13+rke2r1
worker03   Ready    worker                      42m    v1.29.13+rke2r1
worker04   Ready    <none>                      100s   v1.29.13+rke2r1
```

**Set roles for new worker node**
```
root@master01:~# kubectl label node worker04 node-role.kubernetes.io/worker=worker
root@master01:~# kubectl get nodes
NAME       STATUS   ROLES                       AGE     VERSION
master01   Ready    control-plane,etcd,master   93m     v1.29.13+rke2r1
master02   Ready    control-plane,etcd,master   77m     v1.29.13+rke2r1
master03   Ready    control-plane,etcd,master   69m     v1.29.13+rke2r1
worker01   Ready    worker                      63m     v1.29.13+rke2r1
worker02   Ready    worker                      45m     v1.29.13+rke2r1
worker03   Ready    worker                      43m     v1.29.13+rke2r1
worker04   Ready    worker                      2m45s   v1.29.13+rke2r1
```
