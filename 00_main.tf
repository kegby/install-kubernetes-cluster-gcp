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