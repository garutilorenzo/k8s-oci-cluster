#!/bin/bash

wait_for_s3_object(){
  ca_count=$(oci os object list -bn my-very-secure-k8s-bucket --prefix ca | jq -r '.data | length')
  until [ $ca_count -ne 0 ]
  do
      echo "Waiting the ca hash ..."
      sleep 10
      ca_count=$(oci os object list -bn my-very-secure-k8s-bucket --prefix ca | jq -r '.data | length')
  done
}

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
hash_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" ==  "${hash_secret_name}-${environment}") | .id')
token_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${token_secret_name}-${environment}") | .id')

CA_HASH=$(oci vault secret get --secret-id $hash_ocid | base64 -d)
KUBEADM_TOKEN=$(oci vault secret get --secret-id $token_ocid | base64 -d)

cat <<-EOF > /root/kubeadm-join-worker.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_url}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port}
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

k8s_join(){
  kubeadm join --ignore-preflight-errors=NumCPU --config /root/kubeadm-join-worker.yaml
}

until $(curl -k --output /dev/null --silent --head -X GET https://${control_plane_url}:${kube_api_port}); do
  printf '.'
  sleep 5
done

export OCI_CLI_AUTH=instance_principal
wait_for_s3_object
render_kubejoin
k8s_join