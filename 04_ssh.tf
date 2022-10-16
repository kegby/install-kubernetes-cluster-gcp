resource "null_resource" "cp_certs_workers_nodes" {
  count = var.worker_nodes
  depends_on = [google_compute_instance.worker, local_file.kubelets_private_keys, local_file.kubelets_certs, local_file.root_cert, local_file.ssh_private_key_pem]
  connection {
    user = "${split("@", data.google_client_openid_userinfo.me.email)[0]}"
    private_key = tls_private_key.ssh.private_key_pem
    timeout = "3m"
    host = "${google_compute_instance.worker[count.index].network_interface.0.access_config.0.nat_ip}"
  }
  provisioner "file" {
    source      = "certs/ca/ca.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/ca.pem"
  }
  provisioner "file" {
    source      = "certs/kubelet/kubelet-worker-${count.index}-key.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kubelet-worker-${count.index}-key.pem"
  }
  provisioner "file" {
    source      = "certs/kubelet/kubelet-worker-${count.index}.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kubelet-worker-${count.index}.pem"
  }  
}

resource "null_resource" "cp_certs_controller_nodes" {
  count = 3
  depends_on = [google_compute_instance.control_panel, local_file.root_cert, local_file.ssh_private_key_pem, local_file.root_private_key, local_file.api_server_private_key, local_file.api_server_cert, local_file.service_account_cert, local_file.service_account_private_key]
  connection {
    user = "${split("@", data.google_client_openid_userinfo.me.email)[0]}"
    private_key = tls_private_key.ssh.private_key_pem
    timeout = "3m"
    host = "${google_compute_instance.control_panel[count.index].network_interface.0.access_config.0.nat_ip}"
  }
  provisioner "file" {
    source      = "certs/ca/ca.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/ca.pem"
  }
  provisioner "file" {
    source      = "certs/ca/ca-key.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/ca-key.pem"
  }
  provisioner "file" {
    source      = "certs/api_server/kubernetes-key.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kubernetes-key.pem"
  }  
  provisioner "file" {
    source      = "certs/api_server/kubernetes.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kubernetes.pem"
  }
    provisioner "file" {
    source      = "certs/service_account/service-account-key.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/service-account-key.pem"
  }
    provisioner "file" {
    source      = "certs/service_account/service-account.pem"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/service-account.pem"
  }      
}

resource "null_resource" "worker-config-provision" {
  count = var.worker_nodes
  depends_on = [google_compute_instance.worker, null_resource.localexec_kube_proxy, null_resource.localexec_kubeconfig]
  connection {
    user = "${split("@", data.google_client_openid_userinfo.me.email)[0]}"
    private_key = tls_private_key.ssh.private_key_pem
    timeout = "3m"
    host = "${google_compute_instance.worker[count.index].network_interface.0.access_config.0.nat_ip}"
  }
  provisioner "file" {
    source      = "worker-${count.index}.kubeconfig"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/worker-${count.index}.kubeconfig"
  }
  provisioner "file" {
    source      = "kube-proxy.kubeconfig"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kube-proxy.kubeconfig"
  }  
}

resource "null_resource" "cp_kubeconfig_controller_nodes" {
  count = 3
  depends_on = [google_compute_instance.control_panel, null_resource.localexec_controller, null_resource.localexec_scheduler, null_resource.localexec_admin, null_resource.cp_certs_controller_nodes]
  connection {
    user = "${split("@", data.google_client_openid_userinfo.me.email)[0]}"
    private_key = tls_private_key.ssh.private_key_pem
    timeout = "3m"
    host = "${google_compute_instance.control_panel[count.index].network_interface.0.access_config.0.nat_ip}"
  }
  provisioner "file" {
    source      = "admin.kubeconfig"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/admin.kubeconfig"
  }
  provisioner "file" {
    source      = "kube-controller-manager.kubeconfig"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kube-controller-manager.kubeconfig"
  }
  provisioner "file" {
    source      = "kube-scheduler.kubeconfig"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/kube-scheduler.kubeconfig"
  }        
  provisioner "file" {
    source      = "encryption-config.yaml"
    destination = "/home/${split("@", data.google_client_openid_userinfo.me.email)[0]}/encryption-config.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/"
    ]
  }   
}