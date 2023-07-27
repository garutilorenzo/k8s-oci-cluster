#!/bin/bash

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

check_os(){
  name=$(cat /etc/os-release | grep ^NAME= | sed 's/"//g')
  clean_name=$${name#*=}

  version=$(cat /etc/os-release | grep ^VERSION_ID= | sed 's/"//g')
  clean_version=$${version#*=}
  major=$${clean_version%.*}
  minor=$${clean_version#*.}
  
  if [[ "$clean_name" == "Ubuntu" ]]; then
    operating_system="ubuntu"
  elif [[ "$clean_name" == "Oracle Linux Server" ]]; then
    operating_system="oraclelinux"
  else
    operating_system="undef"
  fi

  echo "K3S install process running on: "
  echo "OS: $operating_system"
  echo "OS Major Release: $major"
  echo "OS Minor Release: $minor"
}

render_containerd_service(){
cat <<-EOF > /etc/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
}

render_config(){
cat <<-EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<-EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

modprobe overlay
modprobe br_netfilter

sudo sysctl --system
}

preflight_oracle(){
  yum check-update
  yum upgrade -y
  yum install -y curl unzip jq openssl

  render_config

  # Disable firewall
  systemctl disable --now firewalld
  # END Disable firewall

  # Disable swap
  swapoff -a 
  rm -rf /.swapfile 
  sed -i '/swapfile/d' /etc/fstab

  # Fix iptables/SELinux bug
  echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /root/local_iptables.cil
  semodule -i /root/local_iptables.cil

  # Set SELinux in permissive mode (effectively disabling it)
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
}

install_oci_cli_oracle(){
  yum install -y curl unzip jq openssl python3 python3-pip
  pip3 install oci-cli
}

setup_cri_oracle(){
  curl -L -o containerd-1.6.16-linux-arm64.tar.gz https://github.com/containerd/containerd/releases/download/v1.6.16/containerd-1.6.16-linux-arm64.tar.gz
  tar Cxzvf /usr/local containerd-1.6.16-linux-arm64.tar.gz

  render_containerd_service

  systemctl daemon-reload
  systemctl enable --now containerd

  curl -L -o runc.arm64 https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.arm64
  install -m 755 runc.arm64 /usr/local/sbin/runc

  curl -L -o  cni-plugins-linux-arm64-v1.2.0.tgz https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-arm64-v1.2.0.tgz
  tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v1.2.0.tgz

  mkdir -p /etc/containerd
  cat /etc/containerd/config.toml | grep -Fx "[grpc]"
  res=$?
  if [ $res -ne 0 ]; then
    containerd config default | tee /etc/containerd/config.toml
  fi
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

  render_crictl_conf

  systemctl restart containerd
  systemctl enable containerd
}

setup_repos_oracle(){
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
}

install_k8s_utils_oracle(){
  sleep 5
  yum install -y kubelet-${k8s_version} kubeadm-${k8s_version} kubectl-${k8s_version} --disableexcludes=kubernetes
  sudo systemctl enable --now kubelet
}

preflight(){
  apt-get update && apt-get upgrade -y

  apt-get install -y \
    ca-certificates \
    unzip \
    software-properties-common \
    curl \
    gnupg \
    openssl \
    lsb-release \
    apt-transport-https \
    jq
  
  render_config
  
  # Disable firewall 
  /usr/sbin/netfilter-persistent stop
  /usr/sbin/netfilter-persistent flush

  systemctl stop netfilter-persistent.service
  systemctl disable netfilter-persistent.service
  # END Disable firewall
}

preflight_longhorn(){
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y open-iscsi util-linux nfs-common
  systemctl nnable --now iscsid.service
}

preflight_longhorn_oracle(){
  yum install -y nfs-utils util-linux
  systemctl enable --now iscsid.service 
}

install_oci_cli(){
  # # Ubuntu 20.04
  # sudo apt remove python3-pip 
  # wget https://bootstrap.pypa.io/get-pip.py
  # sudo python3 get-pip.py

  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  python3 python3-pip
  pip install oci-cli
}

setup_repos(){
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  apt-get update
}

render_crictl_conf(){
cat <<-EOF | tee /etc/crictl.yaml
---
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
EOF
}

setup_cri(){
  apt-get update
  apt-get install -y containerd.io
  mkdir -p /etc/containerd
  cat /etc/containerd/config.toml | grep -Fx "[grpc]"
  res=$?
  if [ $res -ne 0 ]; then
    containerd config default | tee /etc/containerd/config.toml
  fi
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

  render_crictl_conf

  systemctl restart containerd
  systemctl enable containerd
}

install_k8s_utils(){
  sleep 5
  apt-get update
  apt-get install -y kubelet=${k8s_version}* kubeadm=${k8s_version}* kubectl=${k8s_version}*
  apt-mark hold kubelet kubeadm kubectl
}

# Guess the Operating System
check_os

if [[ "$operating_system" == "ubuntu" ]]; then
  preflight
  install_oci_cli
  setup_repos
  setup_cri
  install_k8s_utils
  %{ if install_longhorn }
  preflight_longhorn
  %{ endif }
fi

if [[ "$operating_system" == "oraclelinux" ]]; then
  preflight_oracle
  install_oci_cli_oracle
  setup_repos_oracle
  setup_cri_oracle
  install_k8s_utils_oracle
  %{ if install_longhorn }
  preflight_longhorn_oracle
  %{ endif }
fi