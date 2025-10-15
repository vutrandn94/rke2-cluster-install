# Install nerctl and set config to interact with image containerd (like as docker)

## Install nerctl
```
# LATEST=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | grep tag_name | cut -d '"' -f 4)
# wget https://github.com/containerd/nerdctl/releases/download/${LATEST}/nerdctl-${LATEST#v}-linux-amd64.tar.gz
# tar zxvf nerdctl-${LATEST#v}-linux-amd64.tar.gz
# mv nerdctl /usr/local/bin/
```

## Set config for nerctl
```
# vi /etc/nerdctl/nerdctl.toml

namespace = "k8s.io"
address = "<PATH TO containerd.sock>"
```

**Example with K8S worker installed with RKE2:**
```
# vi /etc/nerdctl/nerdctl.toml 
namespace = "k8s.io"
address = "/var/run/k3s/containerd/containerd.sock"
```

## Recheck after install and config
```
# nerdctl ps
CONTAINER ID    IMAGE                                                                                                               COMMAND                   CREATED         STATUS    PORTS    NAMES
0e2a1cb8a007    docker.io/bitnami/mongodb:8.0.9-debian-12-r2                                                                        "/scripts/setup.sh"       9 days ago      Up                 k8s://common/mongodb-test-0/mongodb
f056597258dc    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/mongodb-test-0
root@worker03:/home/vnpt# nerdctl ps | grep "mongo\|kafka"
146c145c9086    docker.io/bitnami/kafka:4.0.0-debian-12-r5                                                                          "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-external-controller-2/kafka
5db8403c2c02    docker.io/bitnami/kafka:4.0.0-debian-12-r5                                                                          "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-notification-controller-2/kafka
e43437e09b96    docker.io/bitnami/kafka:4.0.0-debian-12-r5                                                                          "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-external-broker-3/kafka
99d4921a2ad8    docker.io/bitnami/kafka:3.9.0-debian-12-r12                                                                         "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-controller-0/kafka
3b6b76d91821    docker.io/bitnami/kafka:4.0.0-debian-12-r5                                                                          "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-notification-broker-0/kafka
8a548499ce9b    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-external-controller-2
a856d7cf3732    docker.io/bitnami/kafka:3.9.0-debian-12-r12                                                                         "/opt/bitnami/script…"    9 days ago      Up                 k8s://common/kafka-broker-1/kafka
bbb280e2c6fd    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-notification-controller-2
a7a87a6076ca    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-controller-0
92f2fc782886    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-notification-broker-0
eb9d73654570    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-external-broker-3
3fee4094c042    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/kafka-broker-1
0e2a1cb8a007    docker.io/bitnami/mongodb:8.0.9-debian-12-r2                                                                        "/scripts/setup.sh"       9 days ago      Up                 k8s://common/mongodb-test-0/mongodb
f056597258dc    docker.io/rancher/mirrored-pause:3.6                                                                                "/pause"                  9 days ago      Up                 k8s://common/mongodb-test-0
```
