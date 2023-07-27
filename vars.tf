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

variable "os_image_id" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "kubernetes"
}

variable "fault_domains" {
  type    = list(any)
  default = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

variable "public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
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

variable "k8s_server_pool_size" {
  type    = number
  default = 1
}

variable "k8s_worker_pool_size" {
  type    = number
  default = 2
}

variable "k8s_version" {
  type    = string
  default = "1.27.3"
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

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "install_nginx_ingress" {
  type    = bool
  default = false
}

variable "nginx_ingress_release" {
  type    = string
  default = "v1.8.1"
}

variable "install_certmanager" {
  type    = bool
  default = true
}

variable "certmanager_release" {
  type    = string
  default = "v1.12.2"
}

variable "certmanager_email_address" {
  type    = string
  default = "changeme@example.com"
}

variable "ingress_controller_http_nodeport" {
  type    = number
  default = 30080
}

variable "ingress_controller_https_nodeport" {
  type    = number
  default = 30443
}

variable "install_longhorn" {
  type    = bool
  default = false
}

variable "longhorn_release" {
  type    = string
  default = "v1.4.3"
}

variable "hash_secret_name" {
  type    = string
  default = "k8s-hash"
}

variable "token_secret_name" {
  type    = string
  default = "k8s-token"
}

variable "cert_secret_name" {
  type    = string
  default = "k8s-cert"
}

variable "kubeconfig_secret_name" {
  type    = string
  default = "k8s-kubeconfig"
}

variable "k8s_extra_worker_node" {
  type    = bool
  default = true
}

variable "expose_kubeapi" {
  type    = bool
  default = false
}