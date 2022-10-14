output "wallarm_lb_ip" {
  value = google_compute_forwarding_rule.wallarm_https.ip_address
}


