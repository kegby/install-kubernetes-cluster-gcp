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
        }    
    ]
}

# Provide Static IP External Address
resource "google_compute_address" "ip_address" {
  name          = "kubernetes-the-hard-way"
  region        = "us-east1"
}

output "static_address" {
  description = "ip address"
  value       = google_compute_address.ip_address.address
}