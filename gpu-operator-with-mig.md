# Divide NVIDIA GPU to many short resource part (single mode)

> [!NOTE]
> First, let's reference and perform steps like this turtorial https://github.com/vutrandn94/rke2-cluster-install/blob/main/gpu-operators.md and https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html#about-multi-instance-gpu

## Menu
- [Start configuration](#start-configuration)
- [Recheck on GPU worker node](#recheck-on-gpu-worker-node)
- [Run 1 workload test GPU allocate](#run-1-workload-test-gpu-allocate)

## Start configuration
> [!NOTE]
> In this example, i have 2 gpu worker node attached one NVIDIA A30 (24GB VRAM) for each. I will action divide 1 GPU with 4 profile as 6GB VRAM**

| Hostname | IP Address | OS | Role | RKE Version | GPU | Taint | GPU Profile |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| gpu-worker-01 | 10.171.132.132 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | 1 | dedicated=gpu:NoSchedule | all-1g.6gb |
| gpu-worker-01 | 10.171.132.133 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | 1 | dedicated=gpu:NoSchedule | all-1g.6gb |


> [!NOTE]
> MIG Manager requires that no user workloads are running on the GPUs being configured. In some cases, the node may need to be rebooted, such as a CSP, so the node might need to be cordoned before changing the MIG mode or the MIG geometry on the GPUs.

```
# nvidia-smi 

Tue Mar  3 09:08:25 2026       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.274.02             Driver Version: 535.274.02   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A30                     Off | 00000000:00:06.0 Off |                   On |
| N/A   47C    P0              78W / 165W |     50MiB / 24576MiB |     N/A      Default |
|                                         |                      |              Enabled |
+-----------------------------------------+----------------------+----------------------+ 
```

```
# for i in gpu-worker-01 gpu-worker-02; do kubectl get node $i -o jsonpath='{.status.allocatable}' | jq; done
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819916Ki",
  "nvidia.com/gpu": "1",
  "pods": "110"
}
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819916Ki",
  "nvidia.com/gpu": "1",
  "pods": "110"
}

# kubectl config set-context --current --namespace gpu-operator

# kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    --type='json' \
    -p='[{"op":"replace", "path":"/spec/mig/strategy", "value":"single"}]'

# kubectl label nodes gpu-worker-01 nvidia.com/mig.config=all-1g.6gb --overwrite

# kubectl label nodes gpu-worker-02 nvidia.com/mig.config=all-1g.6gb --overwrite

# kubectl logs -f daemonset/nvidia-mig-manager
Applying the selected MIG config to the node
time="2026-03-02T15:43:36+07:00" level=debug msg="Parsing config file..."
time="2026-03-02T15:43:36+07:00" level=debug msg="Selecting specific MIG config..."
time="2026-03-02T15:43:36+07:00" level=debug msg="Running apply-start hook"
time="2026-03-02T15:43:36+07:00" level=debug msg="Checking current MIG mode..."
time="2026-03-02T15:43:36+07:00" level=debug msg="Walking MigConfig for (devices=all)"
time="2026-03-02T15:43:36+07:00" level=debug msg="  GPU 0: 0x20B710DE"
time="2026-03-02T15:43:36+07:00" level=debug msg="    Asserting MIG mode: Enabled"
time="2026-03-02T15:43:36+07:00" level=debug msg="    MIG capable: true\n"
time="2026-03-02T15:43:36+07:00" level=debug msg="    Current MIG mode: Enabled"
time="2026-03-02T15:43:36+07:00" level=debug msg="Checking current MIG device configuration..."
time="2026-03-02T15:43:36+07:00" level=debug msg="Walking MigConfig for (devices=all)"
time="2026-03-02T15:43:36+07:00" level=debug msg="  GPU 0: 0x20B710DE"
time="2026-03-02T15:43:36+07:00" level=debug msg="    Asserting MIG config: map[1g.6gb:4]"
time="2026-03-02T15:43:36+07:00" level=debug msg="Running pre-apply-config hook"
time="2026-03-02T15:43:36+07:00" level=debug msg="Applying MIG device configuration..."
time="2026-03-02T15:43:36+07:00" level=debug msg="Walking MigConfig for (devices=all)"
time="2026-03-02T15:43:36+07:00" level=debug msg="  GPU 0: 0x20B710DE"
time="2026-03-02T15:43:36+07:00" level=debug msg="    MIG capable: true\n"
time="2026-03-02T15:43:36+07:00" level=debug msg="    Updating MIG config: map[1g.6gb:4]"
time="2026-03-02T15:43:36+07:00" level=debug msg="Running apply-exit hook"
MIG configuration applied successfully
Restarting all GPU clients previously shutdown on the host by restarting their systemd services
Restarting validator pod to re-run all validations
pod "nvidia-operator-validator-5rjxq" deleted
Restarting all GPU clients previously shutdown in Kubernetes by reenabling their component-specific nodeSelector labels
node/gpu-worker-01 labeled
Changing the 'nvidia.com/mig.config.state' node label to 'success'
node/gpu-worker-01 labeled
time="2026-03-02T08:43:40Z" level=info msg="Successfully updated to MIG config: all-1g.6gb"
time="2026-03-02T08:43:40Z" level=info msg="Waiting for change to 'nvidia.com/mig.config' label"
```

> [!NOTE]
> Node labels "nvidia.com/mig.config=all-1g.6gb", "nvidia.com/mig.config.state=success" => Successfully updated to MIG profile config: all-1g.6gb

```
# kubectl describe node gpu-worker-01 gpu-worker-02 | grep "mig"
                    nvidia.com/gpu.deploy.mig-manager=true
                    nvidia.com/mig.capable=true
                    nvidia.com/mig.config=all-1g.6gb
                    nvidia.com/mig.config.state=success
                    nvidia.com/mig.strategy=single
  gpu-operator                     nvidia-mig-manager-7v9zg                             0 (0%)        0 (0%)      0 (0%)           0 (0%)         18h
                    nvidia.com/gpu.deploy.mig-manager=true
                    nvidia.com/mig.capable=true
                    nvidia.com/mig.config=all-1g.6gb
                    nvidia.com/mig.config.state=success
                    nvidia.com/mig.strategy=single
  gpu-operator                nvidia-mig-manager-7lvmf                             0 (0%)        0 (0%)      0 (0%)           0 (0%)         18h


# for i in gpu-worker-01 gpu-worker-02; do kubectl get node $i -o jsonpath='{.status.allocatable}' | jq; done
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819916Ki",
  "nvidia.com/gpu": "4",
  "pods": "110"
}
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819944Ki",
  "nvidia.com/gpu": "4",
  "pods": "110"
}

# kubectl get all -n gpu-operator

NAME                                                              READY   STATUS      RESTARTS      AGE
pod/gpu-feature-discovery-j5gdv                                   1/1     Running     0             17h
pod/gpu-feature-discovery-tsszb                                   1/1     Running     0             17h
pod/gpu-operator-678fd597b7-fnzm7                                 1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-gc-5df6bddb8b-r5hmf       1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-master-5d7584755c-h626k   1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-worker-2pl4f              1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-worker-77hm4              1/1     Running     3 (17h ago)   18h
pod/gpu-operator-node-feature-discovery-worker-c2h6q              1/1     Running     3 (17h ago)   18h
pod/gpu-operator-node-feature-discovery-worker-jtwrj              1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-worker-p8nht              1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-worker-tkdst              1/1     Running     0             18h
pod/gpu-operator-node-feature-discovery-worker-vn9sp              1/1     Running     0             18h
pod/nvidia-container-toolkit-daemonset-gp7mw                      1/1     Running     3 (17h ago)   18h
pod/nvidia-container-toolkit-daemonset-mtf7x                      1/1     Running     3 (17h ago)   18h
pod/nvidia-cuda-validator-bv8k7                                   0/1     Completed   0             17h
pod/nvidia-cuda-validator-hx6jb                                   0/1     Completed   0             17h
pod/nvidia-dcgm-exporter-6kp7z                                    1/1     Running     0             17h
pod/nvidia-dcgm-exporter-mdgdx                                    1/1     Running     0             17h
pod/nvidia-device-plugin-daemonset-6bbv6                          1/1     Running     0             17h
pod/nvidia-device-plugin-daemonset-mjtmg                          1/1     Running     0             17h
pod/nvidia-mig-manager-7lvmf                                      1/1     Running     2 (17h ago)   18h
pod/nvidia-mig-manager-7v9zg                                      1/1     Running     3             18h
pod/nvidia-operator-validator-h9n6z                               1/1     Running     0             17h
pod/nvidia-operator-validator-qjjvl                               1/1     Running     0             17h

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/gpu-operator           ClusterIP   10.43.143.199   <none>        8080/TCP   53d
service/nvidia-dcgm-exporter   ClusterIP   10.43.28.36     <none>        9400/TCP   53d

NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                          AGE
daemonset.apps/gpu-feature-discovery                        2         2         2       2            2           nvidia.com/gpu.deploy.gpu-feature-discovery=true                       53d
daemonset.apps/gpu-operator-node-feature-discovery-worker   7         7         7       7            7           <none>                                                                 53d
daemonset.apps/nvidia-container-toolkit-daemonset           2         2         2       2            2           nvidia.com/gpu.deploy.container-toolkit=true                           53d
daemonset.apps/nvidia-dcgm-exporter                         2         2         2       2            2           nvidia.com/gpu.deploy.dcgm-exporter=true                               53d
daemonset.apps/nvidia-device-plugin-daemonset               2         2         2       2            2           nvidia.com/gpu.deploy.device-plugin=true                               53d
daemonset.apps/nvidia-device-plugin-mps-control-daemon      0         0         0       0            0           nvidia.com/gpu.deploy.device-plugin=true,nvidia.com/mps.capable=true   53d
daemonset.apps/nvidia-driver-daemonset                      0         0         0       0            0           nvidia.com/gpu.deploy.driver=true                                      53d
daemonset.apps/nvidia-mig-manager                           2         2         2       2            2           nvidia.com/gpu.deploy.mig-manager=true                                 53d
daemonset.apps/nvidia-operator-validator                    2         2         2       2            2           nvidia.com/gpu.deploy.operator-validator=true                          53d

NAME                                                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/gpu-operator                                 1/1     1            1           53d
deployment.apps/gpu-operator-node-feature-discovery-gc       1/1     1            1           53d
deployment.apps/gpu-operator-node-feature-discovery-master   1/1     1            1           53d

NAME                                                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/gpu-operator-678fd597b7                                 1         1         1       53d
replicaset.apps/gpu-operator-node-feature-discovery-gc-5df6bddb8b       1         1         1       53d
replicaset.apps/gpu-operator-node-feature-discovery-master-5d7584755c   1         1         1       53d
```

## Recheck on GPU worker node
```
# nvidia-smi -L
GPU 0: NVIDIA A30 (UUID: GPU-557d82ee-ae10-a2e4-2753-dab4f8dd39ba)
  MIG 1g.6gb      Device  0: (UUID: MIG-bc4de647-cf8c-52cb-b14b-f958a3268bc8)
  MIG 1g.6gb      Device  1: (UUID: MIG-6d141cba-0c3f-56b5-80de-d425ac0a26b3)
  MIG 1g.6gb      Device  2: (UUID: MIG-ed79367c-adff-5032-9f5b-e9379c1eda88)
  MIG 1g.6gb      Device  3: (UUID: MIG-33197889-217f-59df-bb8d-edbd734ef7ef)

# nvidia-smi 
Tue Mar  3 09:08:25 2026       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.274.02             Driver Version: 535.274.02   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A30                     Off | 00000000:00:06.0 Off |                   On |
| N/A   47C    P0              78W / 165W |     50MiB / 24576MiB |     N/A      Default |
|                                         |                      |              Enabled |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| MIG devices:                                                                          |
+------------------+--------------------------------+-----------+-----------------------+
| GPU  GI  CI  MIG |                   Memory-Usage |        Vol|      Shared           |
|      ID  ID  Dev |                     BAR1-Usage | SM     Unc| CE ENC DEC OFA JPG    |
|                  |                                |        ECC|                       |
|==================+================================+===========+=======================|
|  0    3   0   0  |              12MiB /  5952MiB  | 14      0 |  1   0    1    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0    4   0   1  |              12MiB /  5952MiB  | 14      0 |  1   0    1    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0    5   0   2  |              12MiB /  5952MiB  | 14      0 |  1   0    1    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0    6   0   3  |              12MiB /  5952MiB  | 14      0 |  1   0    1    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
                                                                                         
+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
```

## Run 1 workload test GPU allocate
> [!NOTE]
> Because we have 2 GPU NVIDIA A30 (24GB VRAM) divide with profile "all-1g.6gb" => we can get 8 part of 2 GPU. In this below workload, we'll schedule 10 replicas pod on Deployment and match case have 2 pod with "Pending" state (Because only available 8 GPU after divide resource)

```
# vi test-gpu-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: test-gpu
  name: test-gpu
  namespace: default
spec:
  replicas: 10
  selector:
    matchLabels:
      app: test-gpu
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: test-gpu
    spec:
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpu"
        effect: "NoSchedule"
      containers:
      - image: nvcr.io/nvidia/k8s/cuda-sample:nbody
        name: cuda-sample
        command:
        - sleep
        - "300"
        resources:
          limits:
            nvidia.com/gpu: 1
            cpu: "2"
            memory: "8Gi"
          requests:
            nvidia.com/gpu: 1
            cpu: "1"
            memory: "1Gi"
status: {}

# kubectl apply -f test-gpu-deployment.yaml
deployment.apps/test-gpu created

# kubectl describe deployment.apps/test-gpu -n default
Name:                   test-gpu
Namespace:              default
CreationTimestamp:      Tue, 03 Mar 2026 09:58:12 +0700
Labels:                 app=test-gpu
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=test-gpu
Replicas:               10 desired | 10 updated | 10 total | 8 available | 2 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=test-gpu
  Containers:
   cuda-sample:
    Image:      nvcr.io/nvidia/k8s/cuda-sample:nbody
    Port:       <none>
    Host Port:  <none>
    Command:
      sleep
      300
    Limits:
      cpu:             2
      memory:          8Gi
      nvidia.com/gpu:  1
    Requests:
      cpu:             1
      memory:          1Gi
      nvidia.com/gpu:  1
    Environment:       <none>
    Mounts:            <none>
  Volumes:             <none>
  Node-Selectors:      <none>
  Tolerations:         dedicated=gpu:NoSchedule
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  <none>
NewReplicaSet:   test-gpu-7db488cd4b (10/10 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  86s   deployment-controller  Scaled up replica set test-gpu-7db488cd4b to 10

# kubectl get all -n default
NAME                            READY   STATUS    RESTARTS   AGE
pod/test-gpu-7db488cd4b-6fmx6   0/1     Pending   0          19s
pod/test-gpu-7db488cd4b-89srz   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-c9rtx   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-l58c4   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-mfl9c   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-mmnxl   0/1     Pending   0          19s
pod/test-gpu-7db488cd4b-nwrc7   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-rpl4d   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-szqd5   1/1     Running   0          19s
pod/test-gpu-7db488cd4b-wfmq6   1/1     Running   0          19s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   55d

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/test-gpu   8/10    10           8           20s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/test-gpu-7db488cd4b   10        10        8       20s

# kubectl describe node gpu-worker-01 | grep -A20 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                4180m (17%)  8500m (36%)
  memory             4239Mi (4%)  33536Mi (35%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
  nvidia.com/gpu     4            4
Events:              <none>

# kubectl describe node gpu-worker-02 | grep -A20 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                4180m (17%)  8500m (36%)
  memory             4239Mi (4%)  33536Mi (35%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
  nvidia.com/gpu     4            4
Events:              <none>

# kubectl events -n default
LAST SEEN               TYPE      REASON              OBJECT                           MESSAGE
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-wfmq6
8m55s                   Normal    ScalingReplicaSet   Deployment/test-gpu              Scaled up replica set test-gpu-7db488cd4b to 10
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-l58c4
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   (combined from similar events): Created pod: test-gpu-7db488cd4b-6fmx6
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-mmnxl
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-c9rtx    Successfully assigned default/test-gpu-7db488cd4b-c9rtx to gpu-worker-02
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-szqd5
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-c9rtx
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-89srz
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-l58c4    Successfully assigned default/test-gpu-7db488cd4b-l58c4 to gpu-worker-01
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-szqd5    Successfully assigned default/test-gpu-7db488cd4b-szqd5 to gpu-worker-01
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-89srz    Successfully assigned default/test-gpu-7db488cd4b-89srz to gpu-worker-02
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-rpl4d
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-mfl9c    Successfully assigned default/test-gpu-7db488cd4b-mfl9c to gpu-worker-01
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-rpl4d    Successfully assigned default/test-gpu-7db488cd4b-rpl4d to gpu-worker-01
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-wfmq6    Successfully assigned default/test-gpu-7db488cd4b-wfmq6 to gpu-worker-02
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-nwrc7
8m55s                   Normal    SuccessfulCreate    ReplicaSet/test-gpu-7db488cd4b   Created pod: test-gpu-7db488cd4b-mfl9c
8m55s                   Normal    Scheduled           Pod/test-gpu-7db488cd4b-nwrc7    Successfully assigned default/test-gpu-7db488cd4b-nwrc7 to gpu-worker-02
3m54s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-mfl9c    Started container cuda-sample
3m54s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-mfl9c    Created container cuda-sample
3m54s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-mfl9c    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-l58c4    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-wfmq6    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-rpl4d    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-rpl4d    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-nwrc7    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-szqd5    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-szqd5    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-szqd5    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-nwrc7    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-wfmq6    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-wfmq6    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-rpl4d    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-nwrc7    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-89srz    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-l58c4    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-89srz    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-l58c4    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-c9rtx    Started container cuda-sample
3m53s (x2 over 8m54s)   Normal    Created             Pod/test-gpu-7db488cd4b-c9rtx    Created container cuda-sample
3m53s (x2 over 8m54s)   Normal    Pulled              Pod/test-gpu-7db488cd4b-c9rtx    Container image "nvcr.io/nvidia/k8s/cuda-sample:nbody" already present on machine
3m53s (x2 over 8m54s)   Normal    Started             Pod/test-gpu-7db488cd4b-89srz    Started container cuda-sample
3m41s (x2 over 8m55s)   Warning   FailedScheduling    Pod/test-gpu-7db488cd4b-6fmx6    0/12 nodes are available: 2 node(s) had untolerated taint {node-role.kubernetes.io/infras: true}, 3 node(s) had untolerated taint {node-role.kubernetes.io/etcd: true}, 7 Insufficient nvidia.com/gpu. preemption: 0/12 nodes are available: 5 Preemption is not helpful for scheduling, 7 No preemption victims found for incoming pod.
3m41s (x2 over 8m55s)   Warning   FailedScheduling    Pod/test-gpu-7db488cd4b-mmnxl    0/12 nodes are available: 2 node(s) had untolerated taint {node-role.kubernetes.io/infras: true}, 3 node(s) had untolerated taint {node-role.kubernetes.io/etcd: true}, 7 Insufficient nvidia.com/gpu. preemption: 0/12 nodes are available: 5 Preemption is not helpful for scheduling, 7 No preemption victims found for incoming pod.
``` 
