variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "environment" {
  type = string
}

variable "uuid" {
  type = string
}

variable "fault_domains" {
  type    = list(any)
  default = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

variable "PATH_TO_PUBLIC_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
}

variable "PATH_TO_PRIVATE_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "Path to your private key"
}

variable "os_image_id" {
  type    = string
  default = "ocid1.image.oc1.eu-zurich-1.aaaaaaaag2uyozo7266bmg26j5ixvi42jhaujso2pddpsigtib6vfnqy5f6q" # Canonical-Ubuntu-20.04-aarch64-2022.01.18-0
}

variable "compute_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "public_lb_shape" {
  type    = string
  default = "flexible"
}

variable "oci_identity_dynamic_group_name" {
  type        = string
  default     = "Compute_Dynamic_Group"
  description = "Dynamic group which contains all instance in this compartment"
}

variable "oci_identity_policy_name" {
  type        = string
  default     = "Compute_To_Oci_Api_Policy"
  description = "Policy to allow dynamic group, to read OCI api without auth"
}

variable "oci_core_vcn_dns_label" {
  type    = string
  default = "defaultvcn"
}

variable "oci_core_subnet_dns_label10" {
  type    = string
  default = "defaultsubnet10"
}

variable "oci_core_subnet_dns_label11" {
  type    = string
  default = "defaultsubnet11"
}

variable "oci_core_vcn_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "oci_core_subnet_cidr10" {
  type    = string
  default = "10.0.0.0/24"
}

variable "oci_core_subnet_cidr11" {
  type    = string
  default = "10.0.1.0/24"
}

variable "k8s_load_balancer_name" {
  type    = string
  default = "k8s internal load balancer"
}

variable "public_load_balancer_name" {
  type    = string
  default = "k8s public LB"
}

variable "http_lb_port" {
  type    = number
  default = 80
}

variable "https_lb_port" {
  type    = number
  default = 443
}

variable "PATH_TO_PUBLIC_LB_CERT" {
  type        = string
  description = "Path to the public LB https certificate"
}

variable "PATH_TO_PUBLIC_LB_KEY" {
  type        = string
  description = "Path to the public LB key"
}

variable "k8s_server_pool_size" {
  type    = number
  default = 2
}

variable "k8s_worker_pool_size" {
  type    = number
  default = 2
}

variable "k8s_version" {
  type    = string
  default = "1.23.5"
}

variable "k8s_pod_subnet" {
  type    = string
  default = "10.244.0.0/16"
}

variable "k8s_service_subnet" {
  type    = string
  default = "10.96.0.0/12"
}

variable "k8s_dns_domain" {
  type    = string
  default = "cluster.local"
}

variable "kube_api_port" {
  type        = number
  default     = 6443
  description = "Kubeapi Port"
}

variable "unique_tag_key" {
  type    = string
  default = "k8s-provisioner"
}

variable "unique_tag_value" {
  type    = string
  default = "https://github.com/garutilorenzo/k8s-oci-cluster"
}

variable "extlb_listener_http_port" {
  type    = number
  default = 30080
}

variable "extlb_listener_https_port" {
  type    = number
  default = 30443
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "install_nginx_ingress" {
  type    = bool
  default = false
}

variable "install_longhorn" {
  type    = bool
  default = false
}

variable "longhorn_release" {
  type    = string
  default = "v1.2.3"
}

variable "oci_bucket_name" {
  type    = string
  default = "my-very-secure-k8s-bucket"
}