data "google_compute_zones" "available" {
  region = "us-east1"
}

data "google_client_openid_userinfo" "me" {
}

resource "google_compute_instance" "control_panel" {
  count                      = 3
  depends_on                 = [module.vpc, tls_private_key.ssh]
  name                       = "controller-${count.index}"
  machine_type               = "e2-standard-2"
  zone                       = data.google_compute_zones.available.names[0]
  allow_stopping_for_update  = true
  tags                       = ["kubernetes-the-hard-way", "controller"]
  can_ip_forward	         = "true"

  boot_disk {
    initialize_params {
      image       = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
      size        = "200"
      }
    }

  network_interface {
    subnetwork     = "kubernetes"
    network_ip     = "10.240.0.1${count.index}"
    
    access_config {
      // Ephemeral public IP
    }
  }

    service_account {
      scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

    metadata = {
      ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
      startup-script = file("controller-startup.sh")
  }

}

resource "google_compute_instance" "worker" {
  count                      = 3
  depends_on                 = [module.vpc, tls_private_key.ssh]
  name                       = "worker-${count.index}"
  machine_type               = "e2-standard-2"
  zone                       = data.google_compute_zones.available.names[0]
  allow_stopping_for_update  = true
  tags                       = ["kubernetes-the-hard-way", "worker"]
  can_ip_forward	         = "true"

  boot_disk {
    initialize_params {
      image       = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
      size        = "200"
      }
    }

  network_interface {
    subnetwork     = "kubernetes"
    network_ip     = "10.240.0.2${count.index}"
    
    access_config {
      // Ephemeral public IP
    }
  }

    service_account {
      scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

    metadata = {
      pod-cidr = "10.200.${count.index}.0/24"
      ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
      startup-script = file("worker-startup.sh")
  }
  
}

output "internal_ip" {
  description = "ip address"
  value       = ["${google_compute_instance.worker.*.network_interface.0.network_ip}"]
}

output "external_ip" {
  description = "ip address"
  value       = ["${google_compute_instance.worker.*.network_interface.0.access_config.0.nat_ip}"]
}

output "user" {
  description = "SSH User"
  value       = ["${split("@", data.google_client_openid_userinfo.me.email)[0]}"]
}

output "worker-Metadata" {
  description = "Metadata Value for POD CIR"
  value       = ["${google_compute_instance.worker.*.metadata.pod-cidr}"]
}