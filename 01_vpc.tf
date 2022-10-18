module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 4.0"

    project_id   = "precise-clock-362521"
    network_name = "kubernetes-the-hard-way"

    subnets = [
        {
            subnet_name           = "kubernetes"
            subnet_ip             = "10.240.0.0/24"
            subnet_region         = "us-east1"
        }
    ]

    firewall_rules = [

        # First Rule: kubernetes-the-hard-way-allow-internal
        {
            name                    = "kubernetes-the-hard-way-allow-internal"
            direction               = "INGRESS"
            ranges                  = ["10.240.0.0/24","10.200.0.0/16"]
            
            allow = [
                {
                    protocol = "tcp"
                    ports    = []
                },
                {
                    protocol = "udp"
                    ports    = []
                },
                {
                    protocol = "icmp"
                    ports    = []
                }
            ]
        },

        # Second Rule: kubernetes-the-hard-way-allow-external
        {
            name                    = "kubernetes-the-hard-way-allow-external"
            direction               = "INGRESS"
            ranges                  = ["0.0.0.0/0"]

            allow = [
                {
                    protocol = "tcp"
                    ports    = ["22","6443"]
                },

                {
                    protocol = "icmp"
                    ports    = []
                }
            ]
        },

        # Thirt Rule: kubernetes-the-hard-way-allow-health-check
        {
            name                    = "kubernetes-the-hard-way-allow-health-check"
            direction               = "INGRESS"
            ranges                  = ["209.85.152.0/22","209.85.204.0/22","35.191.0.0/16"]
            
            allow = [
                {
                    protocol = "tcp"
                    ports    = []
                }
            ]
        }    
    ]
}

# Provide Static IP External Address
resource "google_compute_address" "ip_address" {
  name          = "kubernetes-the-hard-way"
  region        = "us-east1"
}

resource "google_compute_http_health_check" "default" {
  depends_on                 = [null_resource.cp_kubeconfig_controller_nodes] 
  name         = "kubernetes"
  request_path = "/healthz"
  description = "Kubernetes Health Check"
  host = "kubernetes.default.svc.cluster.local"
}

resource "google_compute_target_pool" "default" {
  depends_on                 = [google_compute_http_health_check.default] 
  name = "kubernetes-target-pool"
  region = "us-east1"
  project = "precise-clock-362521"

  instances = [
    "${data.google_compute_zones.available.names[0]}/controller-0",
    "${data.google_compute_zones.available.names[0]}/controller-1",
    "${data.google_compute_zones.available.names[0]}/controller-2" 
  ]

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "kubernetes-forwarding-rule"
  depends_on            = [google_compute_target_pool.default]
  port_range            = "6443"
  region                = "us-east1"
  target                = google_compute_target_pool.default.id
  ip_address            = google_compute_address.ip_address.address
}


resource "google_compute_route" "default" {
  count       = 3
  name        = "kubernetes-route-10-200-${count.index}-0-24"
  dest_range  = google_compute_instance.worker[count.index].metadata.pod-cidr
  network     = module.vpc.network_name
  next_hop_ip = google_compute_instance.worker[count.index].network_interface.0.network_ip
}

output "static_address" {
  description = "ip address"
  value       = google_compute_address.ip_address.address
}

output "network-name" {
  description = "network name"
  value       = module.vpc.network_name
  }