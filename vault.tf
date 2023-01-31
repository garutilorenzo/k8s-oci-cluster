resource "oci_kms_vault" "k8s_kms_valult" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-kms-vault-${var.environment}"
  vault_type     = "DEFAULT" # VIRTUAL_PRIVATE,DEFAULT

  freeform_tags = local.tags
}

resource "oci_kms_key" "k8s_kms_key" {
  compartment_id  = var.compartment_ocid
  display_name    = "k8s-kms-key-${var.environment}"
  protection_mode = "HSM"
  key_shape {
    algorithm = "AES"
    length    = "32"
  }
  management_endpoint = oci_kms_vault.k8s_kms_valult.management_endpoint
  freeform_tags       = local.tags
}

resource "oci_vault_secret" "cert_secret" {
  compartment_id = var.compartment_ocid
  key_id         = oci_kms_key.k8s_kms_key.id
  secret_content {
    content_type = "BASE64"

    content = base64encode("empty cert secret")
    name    = "${var.cert_secret_name}-${var.environment}"
  }
  secret_name = "${var.cert_secret_name}-${var.environment}"
  description = "Kubernetes certificate"
  vault_id    = oci_kms_vault.k8s_kms_valult.id

  freeform_tags = local.tags
}

resource "oci_vault_secret" "token_secret" {
  compartment_id = var.compartment_ocid
  key_id         = oci_kms_key.k8s_kms_key.id
  secret_content {
    content_type = "BASE64"

    content = base64encode("empty token secret")
    name    = "${var.token_secret_name}-${var.environment}"
  }
  secret_name = "${var.token_secret_name}-${var.environment}"
  description = "Kubernetes token"
  vault_id    = oci_kms_vault.k8s_kms_valult.id

  freeform_tags = local.tags
}

resource "oci_vault_secret" "hash_secret" {
  compartment_id = var.compartment_ocid
  key_id         = oci_kms_key.k8s_kms_key.id
  secret_content {
    content_type = "BASE64"

    content = base64encode("empty hash secret")
    name    = "${var.hash_secret_name}-${var.environment}"
  }
  secret_name = "${var.hash_secret_name}-${var.environment}"
  description = "Kubernetes hash"
  vault_id    = oci_kms_vault.k8s_kms_valult.id

  freeform_tags = local.tags
}