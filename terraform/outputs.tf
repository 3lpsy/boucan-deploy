output "boucan_server_public_ip" {
  value = aws_instance.main.public_ip
}

output "boucan_server_https_url" {
  value = "https://${var.dns_dashboard_sub}.${var.dns_root}:8443"
}
output "boucan_server_http_url" {
  value = "http://${var.dns_dashboard_sub}.${var.dns_root}:8080"
}

