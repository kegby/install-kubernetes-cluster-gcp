provider tls{}

variable "allowed_uses" {
  default = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth",
    "key_encipherment"
  ]
}

variable "worker_nodes" {
    type     = number
    default  = 3
}

# SSH Keys
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = ".ssh/ssh-key.pem"
  file_permission = "0600"
}

# CA Keys-Certs
resource "tls_private_key" "root" {
  algorithm = "RSA"
}
resource "tls_self_signed_cert" "root" {
  private_key_pem       = tls_private_key.root.private_key_pem
  is_ca_certificate     = true
  allowed_uses          = toset(var.allowed_uses)
  validity_period_hours = 8760

  subject {
    common_name         = "Kubernetes"
    organization        = "Kubernetes"
    country             = "US"
    organizational_unit = "CA"
    locality            = "Portland"
    province            = "Oregon"
  }
}
# Store CA Certs and Keys
resource "local_file" "root_private_key" {
  content         = tls_private_key.root.private_key_pem
  filename        = "certs/ca/ca-key.pem"
  file_permission = "0600"
}
resource "local_file" "root_cert" {
  content         = tls_self_signed_cert.root.cert_pem
  filename        = "certs/ca/ca.pem"
  file_permission = "0600"
}

# Admin Keys-Certs
resource "tls_private_key" "admin" {
  algorithm = "RSA"
}
resource "tls_cert_request" "admin" {
  private_key_pem       = tls_private_key.admin.private_key_pem
  subject {
    common_name         = "admin"
    country             = "US"
    organization        = "system:masters"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "admin" {
  cert_request_pem      = tls_cert_request.admin.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "admin_private_key" {
  content         = tls_private_key.admin.private_key_pem
  filename        = "certs/admin/admin-key.pem"
  file_permission = "0600"
}
resource "local_file" "admin_cert" {
  content         = tls_locally_signed_cert.admin.cert_pem
  filename        = "certs/admin/admin.pem"
  file_permission = "0600"
}

# Kubelet Keys-Certs
resource "tls_private_key" "kubelet" {
  count     = var.worker_nodes
  algorithm = "RSA"
  
}
resource "tls_cert_request" "kubelet" {
  depends_on            = [google_compute_instance.worker]  
  count                 = var.worker_nodes  
  private_key_pem       = tls_private_key.kubelet[count.index].private_key_pem
  dns_names             = ["worker-${count.index}"]
  ip_addresses          = ["${google_compute_instance.worker[count.index].network_interface.0.access_config.0.nat_ip}","${google_compute_instance.worker[count.index].network_interface.0.network_ip}"]

  subject {
    common_name         = "system:node:worker-${count.index}"
    country             = "US"
    organization        = "system:nodes"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "kubelet" {
  count                 = var.worker_nodes
  cert_request_pem      = tls_cert_request.kubelet[count.index].cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "kubelets_private_keys" {
  count           = var.worker_nodes
  content         = tls_private_key.kubelet[count.index].private_key_pem
  filename        = "certs/kubelet/kubelet-worker-${count.index}-key.pem"
  file_permission = "0600"
}
resource "local_file" "kubelets_certs" {
  count           = var.worker_nodes  
  content         = tls_locally_signed_cert.kubelet[count.index].cert_pem
  filename        = "certs/kubelet/kubelet-worker-${count.index}.pem"
  file_permission = "0600"
}

# Controller-Manager Keys-Certs
resource "tls_private_key" "controller_manager" {
  algorithm = "RSA"
}
resource "tls_cert_request" "controller_manager" {
  private_key_pem       = tls_private_key.controller_manager.private_key_pem
  subject {
    common_name         = "system:kube-controller-manager"
    country             = "US"
    organization        = "system:kube-controller-manager"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "controller_manager" {
  cert_request_pem      = tls_cert_request.controller_manager.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "controller_manager_private_key" {
  content         = tls_private_key.controller_manager.private_key_pem
  filename        = "certs/controller_manager/kube-controller-manager-key.pem"
  file_permission = "0600"
}
resource "local_file" "controller_manager_cert" {
  content         = tls_locally_signed_cert.controller_manager.cert_pem
  filename        = "certs/controller_manager/kube-controller-manager.pem"
  file_permission = "0600"
}

# kube-proxy Keys-Certs
resource "tls_private_key" "kube_proxy" {
  algorithm = "RSA"
}
resource "tls_cert_request" "kube_proxy" {
  private_key_pem       = tls_private_key.kube_proxy.private_key_pem
  subject {
    common_name         = "system:kube-proxy"
    country             = "US"
    organization        = "system:node-proxier"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "kube_proxy" {
  cert_request_pem      = tls_cert_request.kube_proxy.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "kube_proxy_private_key" {
  content         = tls_private_key.kube_proxy.private_key_pem
  filename        = "certs/kube-proxy/kube-proxy-key.pem"
  file_permission = "0600"
}
resource "local_file" "kube_proxy_cert" {
  content         = tls_locally_signed_cert.kube_proxy.cert_pem
  filename        = "certs/kube-proxy/kube-proxy.pem"
  file_permission = "0600"
}

# kube-scheduler Keys-Certs
resource "tls_private_key" "kube_scheduler" {
  algorithm = "RSA"
}
resource "tls_cert_request" "kube_scheduler" {
  private_key_pem       = tls_private_key.kube_scheduler.private_key_pem
  subject {
    common_name         = "system:kube-scheduler"
    country             = "US"
    organization        = "system:kube-scheduler"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "kube_scheduler" {
  cert_request_pem      = tls_cert_request.kube_scheduler.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "kube_scheduler_private_key" {
  content         = tls_private_key.kube_scheduler.private_key_pem
  filename        = "certs/kube_scheduler/kube-scheduler-key.pem"
  file_permission = "0600"
}
resource "local_file" "kube_scheduler_cert" {
  content         = tls_locally_signed_cert.kube_scheduler.cert_pem
  filename        = "certs/kube_scheduler/kube-scheduler.pem"
  file_permission = "0600"
}

# service-account Keys-Certs
resource "tls_private_key" "service_account" {
  algorithm = "RSA"
}
resource "tls_cert_request" "service_account" {
  private_key_pem       = tls_private_key.service_account.private_key_pem
  subject {
    common_name         = "service-accounts"
    country             = "US"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "service_account" {
  cert_request_pem      = tls_cert_request.service_account.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "service_account_private_key" {
  content         = tls_private_key.service_account.private_key_pem
  filename        = "certs/service_account/service-account-key.pem"
  file_permission = "0600"
}
resource "local_file" "service_account_cert" {
  content         = tls_locally_signed_cert.service_account.cert_pem
  filename        = "certs/service_account/service-account.pem"
  file_permission = "0600"
}

# api_server Keys-Certs
resource "tls_private_key" "api_server" {
  algorithm = "RSA"
}
resource "tls_cert_request" "api_server" {
  private_key_pem       = tls_private_key.api_server.private_key_pem
  depends_on            = [google_compute_address.ip_address]
  dns_names             = ["kubernetes","kubernetes.default","kubernetes.default.svc","kubernetes.default.svc.cluster","kubernetes.svc.cluster.local"]
  ip_addresses          = ["10.32.0.1","10.240.0.10","10.240.0.11","10.240.0.12","${google_compute_address.ip_address.address}","127.0.0.1"]
  subject {
    common_name         = "kubernetes"
    country             = "US"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Portland"
    province            = "Oregon"
  }
}
resource "tls_locally_signed_cert" "api_server" {
  cert_request_pem      = tls_cert_request.api_server.cert_request_pem
  ca_private_key_pem    = tls_private_key.root.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root.cert_pem
  validity_period_hours = 8760
  allowed_uses          = toset(var.allowed_uses)
}
resource "local_file" "api_server_private_key" {
  content         = tls_private_key.api_server.private_key_pem
  filename        = "certs/api_server/kubernetes-key.pem"
  file_permission = "0600"
}
resource "local_file" "api_server_cert" {
  content         = tls_locally_signed_cert.api_server.cert_pem
  filename        = "certs/api_server/kubernetes.pem"
  file_permission = "0600"
}
