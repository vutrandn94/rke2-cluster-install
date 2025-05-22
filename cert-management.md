# Certificate Management
https://docs.rke2.io/security/certificates#certificate-authority-ca-certificates

## Rotating Client and Server Certificates
**Client and Server Certificates**

*RKE2 client and server certificates are valid for 365 days from their date of issuance. Any certificates that are expired, or within 90 days of expiring, are automatically renewed every time RKE2 starts.*


**Rotating Client and Server Certificates Manually (Run sequentially on each node rke2-server listen port 9345 - In example is: master01 -> master02 -> master03)**
```
# systemctl stop rke2-server

# rke2 certificate rotate

# systemctl start rke2-server
```

**Restart rke2-agent on all worker nodes**
```
# systemctl restart rke2-agent
```

*Run script "check-cert.sh" to check  Client and Server Certificates expire time*

## Rotating Certificate Authority (CA)
*This tutorial only available with Self-Signed CA Certificates*
**Run in rke2-server first bootrap cluster  (master01)**
```
root@master01:~# curl -sL https://github.com/k3s-io/k3s/raw/master/contrib/util/rotate-default-ca-certs.sh | PRODUCT=rke2 bash -

root@master01:~# rke2 certificate rotate-ca --path=/var/lib/rancher/rke2/server/rotate-ca

root@master01:~# systemctl restart rke2-server

root@master01:~# ./check-cert.sh 
client-admin.crt:              Feb 20 09:56:13 2026 GMT
client-auth-proxy.crt:         Feb 20 09:56:13 2026 GMT
client-ca.crt:                 Feb 15 09:55:23 2045 GMT
client-ca.nochain.crt:         Feb 15 09:55:23 2045 GMT
client-controller.crt:         Feb 20 09:56:13 2026 GMT
client-kube-apiserver.crt:     Feb 20 09:56:13 2026 GMT
client-rke2-cloud-controller.crt: Feb 20 09:56:13 2026 GMT
client-scheduler.crt:          Feb 20 09:56:13 2026 GMT
client-supervisor.crt:         Feb 20 09:56:13 2026 GMT
request-header-ca.crt:         Feb 15 09:55:23 2045 GMT
server-ca.crt:                 Feb 15 09:55:23 2045 GMT
server-ca.nochain.crt:         Feb 15 09:55:23 2045 GMT
serving-kube-apiserver.crt:    Feb 20 09:56:13 2026 GMT

root@master01:~# cat /var/lib/rancher/rke2/server/node-token 
K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df
```

*Copy node token to replace for remaining master and worker nodes*

**Replace token for all remaining master nodes and restart rke2-server to rotating CA**

*Replace current token with new node token above*

```
# vi /etc/rancher/rke2/config.yaml
---
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
```
```
# systemctl restart rke2-server

# ./check-cert.sh 
client-admin.crt:              Feb 20 10:05:32 2026 GMT
client-auth-proxy.crt:         Feb 20 10:05:32 2026 GMT
client-ca.crt:                 Feb 15 09:55:23 2045 GMT
client-ca.nochain.crt:         Feb 15 09:55:23 2045 GMT
client-controller.crt:         Feb 20 10:05:32 2026 GMT
client-kube-apiserver.crt:     Feb 20 10:05:32 2026 GMT
client-rke2-cloud-controller.crt: Feb 20 10:05:32 2026 GMT
client-scheduler.crt:          Feb 20 10:05:32 2026 GMT
client-supervisor.crt:         Feb 20 10:05:32 2026 GMT
request-header-ca.crt:         Feb 15 09:55:23 2045 GMT
server-ca.crt:                 Feb 15 09:55:23 2045 GMT
server-ca.nochain.crt:         Feb 15 09:55:23 2045 GMT
serving-kube-apiserver.crt:    Feb 20 10:05:32 2026 GMT
```

**Replace new token for all worker nodes and restart rke2-agent to rotating CA**

*Replace current token with new node token above*

```
# vi /etc/rancher/rke2/config.yaml
---
server: "https://master01:9345"
token: "K10db6e85a9ae4b3e5de4b6d0974c95d457ff802ba50bcfa0ec1506b1898747c72c::server:d1f9805b444aede79f8abb0e85cda6df"
node-label:
  - "node.kubernetes.io/role=worker"
```
```
# systemctl restart rke2-agent

# ./check-cert.sh 
client-ca.crt:                 Feb 15 09:55:23 2045 GMT
client-kube-proxy.crt:         Feb 20 10:11:35 2026 GMT
client-kubelet.crt:            Feb 20 10:11:35 2026 GMT
client-rke2-controller.crt:    Feb 20 10:11:36 2026 GMT
server-ca.crt:                 Feb 15 09:55:23 2045 GMT
serving-kubelet.crt:           Feb 20 10:11:35 2026 GMT
```

*If the rotate-ca command returns an error, check the service log for errors. If the command completes successfully, restart RKE2 on all nodes in the cluster - servers first, then agents.*

*Ensure that any nodes that were joined with a secure token, including other server nodes, are reconfigured to use the new token value prior to being restarted. The token may be stored in a .env file, systemd unit, or config.yaml, depending on how the node was configured during initial installation.*
