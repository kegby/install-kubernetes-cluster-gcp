resource "null_resource" "localexec_kubeconfig" {
  depends_on = [local_file.kubelets_private_keys, local_file.kubelets_certs, local_file.root_cert, google_compute_address.ip_address]
  count = 3
  provisioner "local-exec" {
    environment = {
      KUBERNETES_PUBLIC_ADDRESS = google_compute_address.ip_address.address
    }
    command = <<EOF
            kubectl config set-cluster kubernetes-the-hard-way \
                --certificate-authority=certs/ca/ca.pem \
                --embed-certs=true \
                --server=https://$KUBERNETES_PUBLIC_ADDRESS:6443 \
                --kubeconfig=worker-${count.index}.kubeconfig

            kubectl config set-credentials system:node:worker-${count.index} \
                --client-certificate=certs/kubelet/kubelet-worker-${count.index}.pem \
                --client-key=certs/kubelet/kubelet-worker-${count.index}-key.pem \
                --embed-certs=true \
                --kubeconfig=worker-${count.index}.kubeconfig

            kubectl config set-context default \
                --cluster=kubernetes-the-hard-way \
                --user=system:node:worker-${count.index} \
                --kubeconfig=worker-${count.index}.kubeconfig

            kubectl config use-context default --kubeconfig=worker-${count.index}.kubeconfig
        EOF
  }
}

resource "null_resource" "localexec_kube_proxy" {
  depends_on = [local_file.kubelets_private_keys, local_file.kube_proxy_private_key, local_file.kube_proxy_cert, google_compute_address.ip_address]
  provisioner "local-exec" {
    environment = {
      KUBERNETES_PUBLIC_ADDRESS = google_compute_address.ip_address.address
    }
    command = <<EOF
            {
                kubectl config set-cluster kubernetes-the-hard-way \
                    --certificate-authority=certs/ca/ca.pem \
                    --embed-certs=true \
                    --server=https://$KUBERNETES_PUBLIC_ADDRESS:6443 \
                    --kubeconfig=kube-proxy.kubeconfig

                kubectl config set-credentials system:kube-proxy \
                    --client-certificate=certs/kube-proxy/kube-proxy.pem \
                    --client-key=certs/kube-proxy/kube-proxy-key.pem \
                    --embed-certs=true \
                    --kubeconfig=kube-proxy.kubeconfig

                kubectl config set-context default \
                    --cluster=kubernetes-the-hard-way \
                    --user=system:kube-proxy \
                    --kubeconfig=kube-proxy.kubeconfig

                kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
                }
        EOF
  }
}

resource "null_resource" "localexec_controller" {
  depends_on = [local_file.kubelets_private_keys, local_file.controller_manager_cert, local_file.controller_manager_private_key]
  provisioner "local-exec" {
    command = <<EOF
                    {
                    kubectl config set-cluster kubernetes-the-hard-way \
                        --certificate-authority=certs/ca/ca.pem \
                        --embed-certs=true \
                        --server=https://127.0.0.1:6443 \
                        --kubeconfig=kube-controller-manager.kubeconfig

                    kubectl config set-credentials system:kube-controller-manager \
                        --client-certificate=certs/controller_manager/kube-controller-manager.pem \
                        --client-key=certs/controller_manager/kube-controller-manager-key.pem \
                        --embed-certs=true \
                        --kubeconfig=kube-controller-manager.kubeconfig

                    kubectl config set-context default \
                        --cluster=kubernetes-the-hard-way \
                        --user=system:kube-controller-manager \
                        --kubeconfig=kube-controller-manager.kubeconfig

                    kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
                    }
        EOF
  }
}

resource "null_resource" "localexec_scheduler" {
  depends_on = [local_file.kubelets_private_keys, local_file.kube_scheduler_private_key, local_file.kube_scheduler_cert]
  provisioner "local-exec" {
    command = <<EOF
                    {
                    kubectl config set-cluster kubernetes-the-hard-way \
                        --certificate-authority=certs/ca/ca.pem \
                        --embed-certs=true \
                        --server=https://127.0.0.1:6443 \
                        --kubeconfig=kube-scheduler.kubeconfig

                    kubectl config set-credentials system:kube-scheduler \
                        --client-certificate=certs/kube_scheduler/kube-scheduler.pem \
                        --client-key=certs/kube_scheduler/kube-scheduler-key.pem \
                        --embed-certs=true \
                        --kubeconfig=kube-scheduler.kubeconfig

                    kubectl config set-context default \
                        --cluster=kubernetes-the-hard-way \
                        --user=system:kube-scheduler \
                        --kubeconfig=kube-scheduler.kubeconfig

                    kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
                    }
        EOF
  }
}


resource "null_resource" "localexec_admin" {
  depends_on = [local_file.kubelets_private_keys, local_file.admin_private_key, local_file.admin_cert]
  provisioner "local-exec" {
    command = <<EOF
                    {
                    kubectl config set-cluster kubernetes-the-hard-way \
                        --certificate-authority=certs/ca/ca.pem \
                        --embed-certs=true \
                        --server=https://127.0.0.1:6443 \
                        --kubeconfig=admin.kubeconfig

                    kubectl config set-credentials admin \
                        --client-certificate=certs/admin/admin.pem \
                        --client-key=certs/admin/admin-key.pem \
                        --embed-certs=true \
                        --kubeconfig=admin.kubeconfig

                    kubectl config set-context default \
                        --cluster=kubernetes-the-hard-way \
                        --user=admin \
                        --kubeconfig=admin.kubeconfig

                    kubectl config use-context default --kubeconfig=admin.kubeconfig
                    }
        EOF
  }
}

resource "null_resource" "localexec_remote_access" {
  depends_on = [local_file.kubelets_private_keys, local_file.kube_proxy_private_key, local_file.kube_proxy_cert, google_compute_address.ip_address,google_compute_forwarding_rule.google_compute_forwarding_rule]
  provisioner "local-exec" {
    environment = {
      KUBERNETES_PUBLIC_ADDRESS = google_compute_address.ip_address.address
    }
    command = <<EOF
            {
                kubectl config set-cluster kubernetes-the-hard-way \
                    --certificate-authority=certs/ca/ca.pem \
                    --embed-certs=true \
                    --server=https://$KUBERNETES_PUBLIC_ADDRESS:6443

                kubectl config set-credentials admin \
                    --client-certificate=certs/admin/admin.pem \
                    --client-key=certs/admin/admin-key.pem
                    --embed-certs=true \

                kubectl config set-context kubernetes-the-hard-way \
                    --cluster=kubernetes-the-hard-way \
                    --user=admin

                kubectl config use-context kubernetes-the-hard-way
            }
        EOF
  }
}

resource "null_resource" "localexec_delete" {
  provisioner "local-exec" {
    command = "rm admin.kubeconfig kube-scheduler.kubeconfig worker-0.kubeconfig worker-1.kubeconfig worker-2.kubeconfig kube-proxy.kubeconfig kube-controller-manager.kubeconfig "
    when = destroy
  }
}