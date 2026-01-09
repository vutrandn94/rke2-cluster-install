# Deploy NVIDIA operator
> [!NOTE]
> This turtorial only support for OS Ubuntu 22.04 and support for RKE2 versions 1.29 — 1.33. Referal for another OS and another RKE2 version at: https://docs.rke2.io/add-ons/gpu_operators & https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html


## Lab info
| Hostname | IP Address | OS | Role | RKE Version | Taint |
| :--- | :--- | :--- | :--- | :--- | :--- |
| master-01 | 10.171.132.117 | Ubuntu 22.04.5 LTS | master | v1.29.12+rke2r1 | node-role.kubernetes.io/etcd=true:NoExecute |
| master-02 | 10.171.132.118 | Ubuntu 22.04.5 LTS | master | v1.29.12+rke2r1 | node-role.kubernetes.io/etcd=true:NoExecute |
| master-03 | 10.171.132.119 | Ubuntu 22.04.5 LTS | master | v1.29.12+rke2r1 | node-role.kubernetes.io/etcd=true:NoExecute |
| worker-01 | 10.171.132.120 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | - |
| worker-02| 10.171.132.121 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | - |
| worker-03 | 10.171.132.122 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | - |
| worker-04 | 10.171.132.123 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | - |
| worker-05 | 10.171.132.124 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | - |
| gpu-worker-01 | 10.171.132.132 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | dedicated=gpu:NoSchedule | 
| gpu-worker-01 | 10.171.132.133 | Ubuntu 22.04.5 LTS | worker | v1.29.12+rke2r1 | dedicated=gpu:NoSchedule |

## Host OS requirements
**GPU worker node attached 1 NVIDIA GPU. In this example, i have 2 gpu worker node attached one NVIDIA A30 for each.**

- Check GPU model information on GPU worker node
```
# lshw -C display
  *-display:0               
       description: VGA compatible controller
       product: Virtio GPU
       vendor: Red Hat, Inc.
       physical id: 2
       bus info: pci@0000:00:02.0
       logical name: /dev/fb0
       version: 01
       width: 64 bits
       clock: 33MHz
       capabilities: msix vga_controller bus_master cap_list rom fb
       configuration: depth=32 driver=virtio-pci latency=0 mode=1024x768 visual=truecolor xres=1024 yres=768
       resources: iomemory:280-27f irq:10 memory:fe000000-fe7fffff memory:2802000000-2802003fff memory:fd090000-fd090fff memory:c0000-dffff
  *-display:1
       description: 3D controller
       product: GA100GL [A30 PCIe]
       vendor: NVIDIA Corporation
       physical id: 6
       bus info: pci@0000:00:06.0
       version: a1
       width: 64 bits
       clock: 33MHz
       capabilities: pm pciexpress msix bus_master cap_list
       configuration: driver=nvidia latency=0
       resources: iomemory:200-1ff iomemory:280-27f irq:10 memory:fc000000-fcffffff memory:2000000000-27ffffffff memory:2800000000-2801ffffff
```

## Prepare NVIDIA kernel drivers & libraries (Perform on all GPU worker nodes)
> [!NOTE]
> Install NVIDIA kernel drivers & libraries REQUIRE reboot server !

**Option 1: Recommend first choice (Ubuntu will auto detect and find available NVIDIA kernel drivers & libraries)**
```
# apt update

# apt install -y ubuntu-drivers-common

# ubuntu-drivers autoinstall

# reboot
```

**Option 2: Only if option 1 can't complete success**
> [!TIP]
> Let's use command "apt list ..." to find exactly version NVIDIA kernel drivers & libraries.
```
# apt list --all-versions nvidia-headless-* nvidia-utils-* nvidia-driver-*

Listing... Done
nvidia-driver-535/now 535.274.02-0ubuntu0.22.04.1 amd64 [installed,local]

nvidia-headless-535/now 535.274.02-0ubuntu0.22.04.1 amd64 [installed,local]

nvidia-headless-no-dkms-535/now 535.274.02-0ubuntu0.22.04.1 amd64 [installed,local]

nvidia-utils-535/now 535.274.02-0ubuntu0.22.04.1 amd64 [installed,local]
```
```
# apt update

# apt install nvidia-headless-535 nvidia-utils-535 nvidia-driver-535

# reboot
```

## Verify kernel driver and & libraries was correctly installed after reboot (Perform on all GPU worker nodes)
> [!NOTE]
> Require NVIDIA kernel and libnvidia-ml.so lib exist on server.

```
# lsmod | grep nvidia

nvidia_uvm           1511424  4
nvidia_drm             77824  0
nvidia_modeset       1306624  1 nvidia_drm
nvidia              56840192  51 nvidia_uvm,nvidia_modeset
drm_kms_helper        315392  4 virtio_gpu,nvidia_drm
drm                   622592  5 drm_kms_helper,nvidia,virtio_gpu,nvidia_drm
```
```
# cat /proc/driver/nvidia/version

NVRM version: NVIDIA UNIX x86_64 Kernel Module  535.274.02  Thu Sep  4 22:13:52 UTC 2025
GCC version:  gcc version 11.4.0 (Ubuntu 11.4.0-1ubuntu1~22.04.2)
```
```
# find /usr/ -iname libnvidia-ml.so

/usr/lib/x86_64-linux-gnu/libnvidia-ml.so
```

## Deploy GPU operator (NVIDIA operator)
### Perform for K8S cluster mark taint for GPU worker node - (IT'S THIS LAB)
**For RKE2 versions 1.29 — 1.33 (https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/25.3/platform-support.html) - (IT'S THIS LAB RKE2 VERSION)**
```
# vi gpu-operator.yaml

apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: gpu-operator
  namespace: kube-system
spec:
  repo: https://helm.ngc.nvidia.com/nvidia
  chart: gpu-operator
  version: v25.3.4
  targetNamespace: gpu-operator
  createNamespace: true
  valuesContent: |-
    toolkit:
      env:
      - name: CONTAINERD_SOCKET
        value: /run/k3s/containerd/containerd.sock
      - name: ACCEPT_NVIDIA_VISIBLE_DEVICES_ENVVAR_WHEN_UNPRIVILEGED
        value: "false"
      - name: ACCEPT_NVIDIA_VISIBLE_DEVICES_AS_VOLUME_MOUNTS
        value: "true"
    devicePlugin:
      env:
      - name: DEVICE_LIST_STRATEGY
        value: volume-mounts
```
```
# kubectl apply -f gpu-operator.yaml
```

**For RKE2 versions 1.30 — 1.34 (https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/25.10/platform-support.html) - (OPTIONAL)**
```
# vi gpu-operator.yaml

apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: gpu-operator
  namespace: kube-system
spec:
  repo: https://helm.ngc.nvidia.com/nvidia
  chart: gpu-operator
  version: v25.10.1
  targetNamespace: gpu-operator
  createNamespace: true
  valuesContent: |-
    toolkit:
      env:
      - name: CONTAINERD_SOCKET
        value: /run/k3s/containerd/containerd.sock
```
```
# kubectl apply -f gpu-operator.yaml
```

**Set Toleration for GPU operator DaemonSets workload**
| Workload Name | Type | Toleration |
| :--- | :--- | :--- |
| gpu-feature-discovery | Daemonset | dedicated=gpu:NoSchedule |
| gpu-operator-node-feature-discovery-worker | Daemonset | dedicated=gpu:NoSchedule |
| nvidia-container-toolkit-daemonset |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-dcgm-exporter |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-device-plugin-daemonset |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-device-plugin-mps-control-daemon |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-driver-daemonset |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-mig-manager |  Daemonset | dedicated=gpu:NoSchedule |
| nvidia-operator-validator |  Daemonset | dedicated=gpu:NoSchedule |

```
### TOLERATION EXAMPLE TEMPLATE ###
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
```    
```
### VIEW TAINTS FLAG SET FOR GPU WORKER NODE ###

# for i in gpu-worker-01 gpu-worker-02; do echo "$i"; kubectl describe node $i | grep Taint; done

gpu-worker-01
Taints:             dedicated=gpu:NoSchedule
gpu-worker-02
Taints:             dedicated=gpu:NoSchedule 
``` 

```
### TOLERATIONS AFTER SET FOR GPU OPERATOR WORKLOAD ###

# for i in $(kubectl get daemonset -n gpu-operator -o name); do echo "$i"; kubectl describe $i -n gpu-operator | grep Toleration; done

daemonset.apps/gpu-feature-discovery
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/gpu-operator-node-feature-discovery-worker
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-container-toolkit-daemonset
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-dcgm-exporter
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-device-plugin-daemonset
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-device-plugin-mps-control-daemon
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-driver-daemonset
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-mig-manager
  Tolerations:          dedicated=gpu:NoSchedule
daemonset.apps/nvidia-operator-validator
  Tolerations:          dedicated=gpu:NoSchedule
```

```
### VERIFY GPU OPERATOR WORKLOAD DEPLOY ###

# kubectl get deployment -n gpu-operator
NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
gpu-operator                                 1/1     1            1           6h40m
gpu-operator-node-feature-discovery-gc       1/1     1            1           6h40m
gpu-operator-node-feature-discovery-master   1/1     1            1           6h40m

# kubectl get daemonset -n gpu-operator
NAME                                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                          AGE
gpu-feature-discovery                        2         2         2       2            2           nvidia.com/gpu.deploy.gpu-feature-discovery=true                       6h25m
gpu-operator-node-feature-discovery-worker   7         7         7       7            7           <none>                                                                 6h40m
nvidia-container-toolkit-daemonset           2         2         2       2            2           nvidia.com/gpu.deploy.container-toolkit=true                           6h25m
nvidia-dcgm-exporter                         2         2         2       2            2           nvidia.com/gpu.deploy.dcgm-exporter=true                               6h25m
nvidia-device-plugin-daemonset               2         2         2       2            2           nvidia.com/gpu.deploy.device-plugin=true                               6h25m
nvidia-device-plugin-mps-control-daemon      0         0         0       0            0           nvidia.com/gpu.deploy.device-plugin=true,nvidia.com/mps.capable=true   6h25m
nvidia-driver-daemonset                      0         0         0       0            0           nvidia.com/gpu.deploy.driver=true                                      6h25m
nvidia-mig-manager                           2         2         2       2            2           nvidia.com/gpu.deploy.mig-manager=true                                 6h25m
nvidia-operator-validator                    2         2         2       2            2           nvidia.com/gpu.deploy.operator-validator=true                          6h25m

# kubectl get pod -n gpu-operator -o wide
NAME                                                          READY   STATUS      RESTARTS        AGE     IP            NODE            NOMINATED NODE   READINESS GATES
gpu-feature-discovery-b68mz                                   1/1     Running     2               6h16m   10.42.9.82    gpu-worker-01   <none>           <none>
gpu-feature-discovery-c6xhv                                   1/1     Running     1 (5h5m ago)    6h16m   10.42.8.199   gpu-worker-02   <none>           <none>
gpu-operator-678fd597b7-s5xdv                                 1/1     Running     0               5h2m    10.42.4.124   worker-01       <none>           <none>
gpu-operator-node-feature-discovery-gc-5df6bddb8b-wchjx       1/1     Running     0               5h2m    10.42.4.28    worker-01       <none>           <none>
gpu-operator-node-feature-discovery-master-5d7584755c-7c5kj   1/1     Running     0               5h1m    10.42.4.47    worker-01       <none>           <none>
gpu-operator-node-feature-discovery-worker-4f842              1/1     Running     2 (5h5m ago)    6h26m   10.42.9.122   gpu-worker-01   <none>           <none>
gpu-operator-node-feature-discovery-worker-84vdj              1/1     Running     2 (4h54m ago)   6h26m   10.42.5.100   worker-03       <none>           <none>
gpu-operator-node-feature-discovery-worker-9dpzc              1/1     Running     2 (5h5m ago)    6h26m   10.42.8.33    gpu-worker-02   <none>           <none>
gpu-operator-node-feature-discovery-worker-dcww5              1/1     Running     2 (4h54m ago)   6h26m   10.42.3.235   worker-05       <none>           <none>
gpu-operator-node-feature-discovery-worker-g2lbl              1/1     Running     2 (4h54m ago)   6h25m   10.42.1.160   worker-04       <none>           <none>
gpu-operator-node-feature-discovery-worker-gh8lv              1/1     Running     1 (4h58m ago)   6h26m   10.42.4.84    worker-01       <none>           <none>
gpu-operator-node-feature-discovery-worker-hb8nn              1/1     Running     2 (4h54m ago)   6h26m   10.42.2.35    worker-02       <none>           <none>
nvidia-container-toolkit-daemonset-khl5x                      1/1     Running     1 (5h5m ago)    6h15m   10.42.9.97    gpu-worker-01   <none>           <none>
nvidia-container-toolkit-daemonset-wqt6w                      1/1     Running     1 (5h5m ago)    6h15m   10.42.8.133   gpu-worker-02   <none>           <none>
nvidia-cuda-validator-c4chx                                   0/1     Completed   0               5h4m    10.42.9.164   gpu-worker-01   <none>           <none>
nvidia-cuda-validator-fkcjg                                   0/1     Completed   0               5h4m    10.42.8.56    gpu-worker-02   <none>           <none>
nvidia-dcgm-exporter-k797x                                    1/1     Running     1 (5h5m ago)    6h13m   10.42.8.135   gpu-worker-02   <none>           <none>
nvidia-dcgm-exporter-kj22x                                    1/1     Running     1 (5h5m ago)    6h13m   10.42.9.225   gpu-worker-01   <none>           <none>
nvidia-device-plugin-daemonset-kkpxd                          1/1     Running     1 (5h5m ago)    6h11m   10.42.8.128   gpu-worker-02   <none>           <none>
nvidia-device-plugin-daemonset-v65zq                          1/1     Running     2               6h11m   10.42.9.165   gpu-worker-01   <none>           <none>
nvidia-mig-manager-hkphp                                      1/1     Running     1 (5h5m ago)    6h7m    10.42.8.214   gpu-worker-02   <none>           <none>
nvidia-mig-manager-sgk4v                                      1/1     Running     2               6h7m    10.42.9.135   gpu-worker-01   <none>           <none>
nvidia-operator-validator-47qxl                               1/1     Running     1 (5h5m ago)    6h8m    10.42.8.40    gpu-worker-02   <none>           <none>
nvidia-operator-validator-kmhww                               1/1     Running     1 (5h5m ago)    6h8m    10.42.9.250   gpu-worker-01   <none>           <none>
```


### Perform for K8S cluster not mark taint for GPU worker node
> [!NOTE]
> Perform like as the same above but ignore STEP Set Toleration for GPU operator DaemonSets workload.

### Verify everything
```
# for NODE in gpu-worker-01 gpu-worker-02; do kubectl get node $NODE -o jsonpath='{.metadata.labels}' | grep "nvidia.com/gpu.deploy.driver"; done

{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","feature.node.kubernetes.io/cpu-cpuid.ADX":"true","feature.node.kubernetes.io/cpu-cpuid.AESNI":"true","feature.node.kubernetes.io/cpu-cpuid.AMXFP8":"true","feature.node.kubernetes.io/cpu-cpuid.AVX":"true","feature.node.kubernetes.io/cpu-cpuid.AVX2":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512BITALG":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512BW":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512CD":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512DQ":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512F":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VBMI":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VBMI2":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VL":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VNNI":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VPOPCNTDQ":"true","feature.node.kubernetes.io/cpu-cpuid.CMPXCHG8":"true","feature.node.kubernetes.io/cpu-cpuid.FMA3":"true","feature.node.kubernetes.io/cpu-cpuid.FXSR":"true","feature.node.kubernetes.io/cpu-cpuid.FXSROPT":"true","feature.node.kubernetes.io/cpu-cpuid.GFNI":"true","feature.node.kubernetes.io/cpu-cpuid.HYPERVISOR":"true","feature.node.kubernetes.io/cpu-cpuid.IBPB":"true","feature.node.kubernetes.io/cpu-cpuid.LAHF":"true","feature.node.kubernetes.io/cpu-cpuid.MOVBE":"true","feature.node.kubernetes.io/cpu-cpuid.OSXSAVE":"true","feature.node.kubernetes.io/cpu-cpuid.SPEC_CTRL_SSBD":"true","feature.node.kubernetes.io/cpu-cpuid.SYSCALL":"true","feature.node.kubernetes.io/cpu-cpuid.SYSEE":"true","feature.node.kubernetes.io/cpu-cpuid.VAES":"true","feature.node.kubernetes.io/cpu-cpuid.VMX":"true","feature.node.kubernetes.io/cpu-cpuid.VPCLMULQDQ":"true","feature.node.kubernetes.io/cpu-cpuid.WBNOINVD":"true","feature.node.kubernetes.io/cpu-cpuid.X87":"true","feature.node.kubernetes.io/cpu-cpuid.XGETBV1":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVE":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVEC":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVEOPT":"true","feature.node.kubernetes.io/cpu-hardware_multithreading":"false","feature.node.kubernetes.io/cpu-model.family":"6","feature.node.kubernetes.io/cpu-model.id":"134","feature.node.kubernetes.io/cpu-model.vendor_id":"Intel","feature.node.kubernetes.io/kernel-config.NO_HZ":"true","feature.node.kubernetes.io/kernel-config.NO_HZ_IDLE":"true","feature.node.kubernetes.io/kernel-version.full":"5.15.0-164-generic","feature.node.kubernetes.io/kernel-version.major":"5","feature.node.kubernetes.io/kernel-version.minor":"15","feature.node.kubernetes.io/kernel-version.revision":"0","feature.node.kubernetes.io/pci-10de.present":"true","feature.node.kubernetes.io/pci-1af4.present":"true","feature.node.kubernetes.io/system-os_release.ID":"ubuntu","feature.node.kubernetes.io/system-os_release.VERSION_ID":"22.04","feature.node.kubernetes.io/system-os_release.VERSION_ID.major":"22","feature.node.kubernetes.io/system-os_release.VERSION_ID.minor":"04","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"gpu-worker-01","kubernetes.io/os":"linux","node-role.kubernetes.io/worker":"worker","nvidia.com/cuda.driver-version.full":"535.274.02","nvidia.com/cuda.driver-version.major":"535","nvidia.com/cuda.driver-version.minor":"274","nvidia.com/cuda.driver-version.revision":"02","nvidia.com/cuda.driver.major":"535","nvidia.com/cuda.driver.minor":"274","nvidia.com/cuda.driver.rev":"02","nvidia.com/cuda.runtime-version.full":"12.2","nvidia.com/cuda.runtime-version.major":"12","nvidia.com/cuda.runtime-version.minor":"2","nvidia.com/cuda.runtime.major":"12","nvidia.com/cuda.runtime.minor":"2","nvidia.com/gfd.timestamp":"1767928015","nvidia.com/gpu-driver-upgrade-state":"upgrade-done","nvidia.com/gpu.compute.major":"8","nvidia.com/gpu.compute.minor":"0","nvidia.com/gpu.count":"1","nvidia.com/gpu.deploy.container-toolkit":"true","nvidia.com/gpu.deploy.dcgm":"true","nvidia.com/gpu.deploy.dcgm-exporter":"true","nvidia.com/gpu.deploy.device-plugin":"true","nvidia.com/gpu.deploy.driver":"pre-installed","nvidia.com/gpu.deploy.gpu-feature-discovery":"true","nvidia.com/gpu.deploy.mig-manager":"true","nvidia.com/gpu.deploy.node-status-exporter":"true","nvidia.com/gpu.deploy.nvsm":"","nvidia.com/gpu.deploy.operator-validator":"true","nvidia.com/gpu.family":"ampere","nvidia.com/gpu.machine":"OpenStack-Nova","nvidia.com/gpu.memory":"24576","nvidia.com/gpu.mode":"compute","nvidia.com/gpu.present":"true","nvidia.com/gpu.product":"NVIDIA-A30","nvidia.com/gpu.replicas":"1","nvidia.com/gpu.sharing-strategy":"none","nvidia.com/mig.capable":"true","nvidia.com/mig.config":"all-disabled","nvidia.com/mig.config.state":"success","nvidia.com/mig.strategy":"single","nvidia.com/mps.capable":"false","nvidia.com/vgpu.present":"false","type":"gpu"}
{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","feature.node.kubernetes.io/cpu-cpuid.ADX":"true","feature.node.kubernetes.io/cpu-cpuid.AESNI":"true","feature.node.kubernetes.io/cpu-cpuid.AMXFP8":"true","feature.node.kubernetes.io/cpu-cpuid.AVX":"true","feature.node.kubernetes.io/cpu-cpuid.AVX2":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512BITALG":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512BW":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512CD":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512DQ":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512F":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VBMI":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VBMI2":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VL":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VNNI":"true","feature.node.kubernetes.io/cpu-cpuid.AVX512VPOPCNTDQ":"true","feature.node.kubernetes.io/cpu-cpuid.CMPXCHG8":"true","feature.node.kubernetes.io/cpu-cpuid.FMA3":"true","feature.node.kubernetes.io/cpu-cpuid.FXSR":"true","feature.node.kubernetes.io/cpu-cpuid.FXSROPT":"true","feature.node.kubernetes.io/cpu-cpuid.GFNI":"true","feature.node.kubernetes.io/cpu-cpuid.HYPERVISOR":"true","feature.node.kubernetes.io/cpu-cpuid.IBPB":"true","feature.node.kubernetes.io/cpu-cpuid.LAHF":"true","feature.node.kubernetes.io/cpu-cpuid.MOVBE":"true","feature.node.kubernetes.io/cpu-cpuid.OSXSAVE":"true","feature.node.kubernetes.io/cpu-cpuid.SPEC_CTRL_SSBD":"true","feature.node.kubernetes.io/cpu-cpuid.SYSCALL":"true","feature.node.kubernetes.io/cpu-cpuid.SYSEE":"true","feature.node.kubernetes.io/cpu-cpuid.VAES":"true","feature.node.kubernetes.io/cpu-cpuid.VMX":"true","feature.node.kubernetes.io/cpu-cpuid.VPCLMULQDQ":"true","feature.node.kubernetes.io/cpu-cpuid.WBNOINVD":"true","feature.node.kubernetes.io/cpu-cpuid.X87":"true","feature.node.kubernetes.io/cpu-cpuid.XGETBV1":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVE":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVEC":"true","feature.node.kubernetes.io/cpu-cpuid.XSAVEOPT":"true","feature.node.kubernetes.io/cpu-hardware_multithreading":"false","feature.node.kubernetes.io/cpu-model.family":"6","feature.node.kubernetes.io/cpu-model.id":"134","feature.node.kubernetes.io/cpu-model.vendor_id":"Intel","feature.node.kubernetes.io/kernel-config.NO_HZ":"true","feature.node.kubernetes.io/kernel-config.NO_HZ_IDLE":"true","feature.node.kubernetes.io/kernel-version.full":"5.15.0-164-generic","feature.node.kubernetes.io/kernel-version.major":"5","feature.node.kubernetes.io/kernel-version.minor":"15","feature.node.kubernetes.io/kernel-version.revision":"0","feature.node.kubernetes.io/pci-10de.present":"true","feature.node.kubernetes.io/pci-1af4.present":"true","feature.node.kubernetes.io/system-os_release.ID":"ubuntu","feature.node.kubernetes.io/system-os_release.VERSION_ID":"22.04","feature.node.kubernetes.io/system-os_release.VERSION_ID.major":"22","feature.node.kubernetes.io/system-os_release.VERSION_ID.minor":"04","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"gpu-worker-02","kubernetes.io/os":"linux","node-role.kubernetes.io/worker":"worker","nvidia.com/cuda.driver-version.full":"535.274.02","nvidia.com/cuda.driver-version.major":"535","nvidia.com/cuda.driver-version.minor":"274","nvidia.com/cuda.driver-version.revision":"02","nvidia.com/cuda.driver.major":"535","nvidia.com/cuda.driver.minor":"274","nvidia.com/cuda.driver.rev":"02","nvidia.com/cuda.runtime-version.full":"12.2","nvidia.com/cuda.runtime-version.major":"12","nvidia.com/cuda.runtime-version.minor":"2","nvidia.com/cuda.runtime.major":"12","nvidia.com/cuda.runtime.minor":"2","nvidia.com/gfd.timestamp":"1767928010","nvidia.com/gpu-driver-upgrade-state":"upgrade-done","nvidia.com/gpu.compute.major":"8","nvidia.com/gpu.compute.minor":"0","nvidia.com/gpu.count":"1","nvidia.com/gpu.deploy.container-toolkit":"true","nvidia.com/gpu.deploy.dcgm":"true","nvidia.com/gpu.deploy.dcgm-exporter":"true","nvidia.com/gpu.deploy.device-plugin":"true","nvidia.com/gpu.deploy.driver":"pre-installed","nvidia.com/gpu.deploy.gpu-feature-discovery":"true","nvidia.com/gpu.deploy.mig-manager":"true","nvidia.com/gpu.deploy.node-status-exporter":"true","nvidia.com/gpu.deploy.nvsm":"","nvidia.com/gpu.deploy.operator-validator":"true","nvidia.com/gpu.family":"ampere","nvidia.com/gpu.machine":"OpenStack-Nova","nvidia.com/gpu.memory":"24576","nvidia.com/gpu.mode":"compute","nvidia.com/gpu.present":"true","nvidia.com/gpu.product":"NVIDIA-A30","nvidia.com/gpu.replicas":"1","nvidia.com/gpu.sharing-strategy":"none","nvidia.com/mig.capable":"true","nvidia.com/mig.config":"all-disabled","nvidia.com/mig.config.state":"success","nvidia.com/mig.strategy":"single","nvidia.com/mps.capable":"false","nvidia.com/vgpu.present":"false","type":"gpu"}
```

```
# for NODE in gpu-worker-01 gpu-worker-02; do kubectl get node $NODE -o jsonpath='{.status.allocatable}'  | jq ; done
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819928Ki",
  "nvidia.com/gpu": "1",        ===> GPU WORKER NODE WILL SHOW value "nvidia.com/gpu"
  "pods": "110"
}
{
  "cpu": "23600m",
  "ephemeral-storage": "988420490080",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "97819940Ki",
  "nvidia.com/gpu": "1",        ===> GPU WORKER NODE WILL SHOW value "nvidia.com/gpu"
  "pods": "110"
}
```

```
### PERFORM ON GPU WORKER NODE ###

# ls /usr/local/nvidia/toolkit/nvidia-container-runtime
/usr/local/nvidia/toolkit/nvidia-container-runtime
```


```
### PERFORM ON GPU WORKER NODE ###

# grep nvidia /var/lib/rancher/rke2/agent/etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia"]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia".options]
  BinaryName = "/usr/local/nvidia/toolkit/nvidia-container-runtime"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia-cdi"]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia-cdi".options]
  BinaryName = "/usr/local/nvidia/toolkit/nvidia-container-runtime.cdi"
```

### Run 1 workload test GPU allocate
```
# vi test-gpu.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-gpu-pod
  namespace: default
spec:
  containers:
    - name: cuda-container
      image: nvcr.io/nvidia/k8s/cuda-sample:nbody
      args: ["nbody", "-gpu", "-benchmark"]
      resources:
        limits:
          nvidia.com/gpu: 1
          cpu: "2"
          memory: "8Gi"
        requests:
          nvidia.com/gpu: 1
          cpu: "1"
          memory: "4Gi"
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"


# kubectl apply -f test-gpu.yaml
pod/my-gpu-pod created


# kubectl describe pod my-gpu-pod -n default
Name:             my-gpu-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             gpu-worker-01/10.171.132.132
Start Time:       Fri, 09 Jan 2026 15:32:40 +0700
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.42.9.127
IPs:
  IP:  10.42.9.127
Containers:
  cuda-container:
    Container ID:  containerd://514c7123226efa04119f545bd69e7b6cd65b42faad37bbf2a798b1e2bcf10d53
    Image:         nvcr.io/nvidia/k8s/cuda-sample:nbody
    Image ID:      nvcr.io/nvidia/k8s/cuda-sample@sha256:59261e419d6d48a772aad5bb213f9f1588fcdb042b115ceb7166c89a51f03363
    Port:          <none>
    Host Port:     <none>
    Args:
      nbody
      -gpu
      -benchmark
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Fri, 09 Jan 2026 15:34:19 +0700
      Finished:     Fri, 09 Jan 2026 15:34:19 +0700
    Ready:          False
    Restart Count:  4
    Limits:
      cpu:             2
      memory:          8Gi
      nvidia.com/gpu:  1
    Requests:
      cpu:             1
      memory:          4Gi
      nvidia.com/gpu:  1
    Environment:       <none>
    Mounts:            <none>
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:                      <none>
QoS Class:                    Burstable
Node-Selectors:               <none>
Tolerations:                  dedicated=gpu:NoSchedule
                              node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                              node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```
