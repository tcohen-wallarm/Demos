data "google_compute_image" "wallarm_image" {
  project = "wallarm-node-195710"
  name    = var.wallarm_image
}

data "google_compute_zones" "available" {
}

resource "google_compute_instance_template" "wallarm" {
  name_prefix  = var.name_prefix
  machine_type = "f1-micro"
  region       = var.region

  disk {
    source_image = data.google_compute_image.wallarm_image.self_link
  }

  network_interface {
    network    = var.vpc_self_link
    subnetwork = "${var.name_prefix}-subnet-${data.google_compute_zones.available.names[0]}"
  }

  # image support required for user-data https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance
  # shortcut for demo purposes

  metadata_startup_script = <<-EOF

 cat << DEFAULT > /etc/nginx/sites-available/default
     server {
       listen 80 default_server;
       server_name _;
       wallarm_mode monitoring;
       # wallarm_instance 1;
       wallarm_enable_libdetection on;
       proxy_request_buffering on;
       location /healthcheck {
         return 200;
       }
       location / {
         # setting the address for request forwarding
         proxy_pass http://${var.origin_ip};
         proxy_set_header Host \$host;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         set_real_ip_from 10.0.0.0/8;
         real_ip_header X-Forwarded-For;
       }
     }
    server {
        listen      443;
        server_name default_server;
        
        ssl                     on;
        ssl_protocols           TLSv1.2 TLSv1;
        ssl_certificate         server.pem;
        ssl_certificate_key     server.key;
        ssl_client_certificate  ca.pem;
        # ssl_crl               revoked.crt;
        ssl_verify_client       off;

        location / {
            proxy_pass http://${var.origin_ip};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            set_real_ip_from 10.0.0.0/8;
            real_ip_header X-Forwarded-For;
        }
    }
DEFAULT

echo "100003" >  /etc/nginx/serial
touch /etc/nginx/certindex.txt  

cat << TMP_CNF > /etc/nginx/tmp.cnf
#
# OpenSSL configuration file.
#
 
# Establish working directory.
 
[ ca ]
default_ca				= CA_default
 
[ CA_default ]
serial					= /etc/nginx/serial
database				= /etc/nginx/certindex.txt
new_certs_dir				= /etc/nginx
certificate				= /etc/nginxcacert.pem
private_key				= /etc/nginx/cakey.pem
default_days				= 365
default_md				= sha256
preserve				= no
email_in_dn				= no
nameopt					= default_ca
certopt					= default_ca
policy					= policy_match
 
[ policy_match ]
countryName				= match
stateOrProvinceName			= match
organizationName			= match
organizationalUnitName			= optional
commonName				= supplied
emailAddress				= optional
[ usr_cert ]
[ server_cert ] 
[ req ]
default_bits				= 4096			# Size of keys
default_keyfile				= key.pem		# name of generated keys
default_md				= sha256				# message digest algorithm
string_mask				= nombstr		# permitted characters
distinguished_name			= req_distinguished_name
req_extensions				= v3_req
 
[ req_distinguished_name ]
# Variable name				Prompt string
#-------------------------	  ----------------------------------
0.organizationName			= Organization Name (company)
organizationalUnitName			= Organizational Unit Name (department, division)
emailAddress				= Email Address
emailAddress_max			= 40
localityName				= Locality Name (city, district)
stateOrProvinceName			= State or Province Name (full name)
countryName				= Country Name (2 letter code)
countryName_min				= 2
countryName_max				= 2
commonName				= Common Name (hostname, IP, or your name)
commonName_max				= 64
 
# Default values for the above, for consistency and less typing.
# Variable name				Value
#------------------------	  ------------------------------
0.organizationName_default		= wallarm-test
localityName_default			= San Francisco
stateOrProvinceName_default		= CA
countryName_default			= US
emailAddress				= none@invalid
commonName_default              = localhost
 
[ v3_ca ]
basicConstraints			= CA:TRUE
subjectKeyIdentifier			= hash
authorityKeyIdentifier			= keyid:always,issuer:always
 
[ v3_req ]
basicConstraints			= CA:FALSE
subjectKeyIdentifier			= hash

[alt_names]
DNS.1 = localhost             # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.2 = localhost.localdomain # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1              # Optionally, add an IP address (if the connection which you have planned requires it)   

TMP_CNF

    openssl genrsa -out /etc/nginx/ca.key 2048 && \
    printf "\\n\\n\\n\\n\\n\\n\\n" | \
    openssl req -config /etc/nginx/tmp.cnf -x509 -new -nodes -key /etc/nginx/ca.key -sha256 -days 1024 -out /etc/nginx/ca.pem
    printf "\\n"

    name=server
    openssl genrsa -out /etc/nginx/$name.key 4096 && \
    printf "\\n\\n\\n\\n\\nlocalhost\\n\\n1234\\n\\n" | \
    openssl req -batch -config /etc/nginx/tmp.cnf -new -key /etc/nginx/$name.key -out /etc/nginx/$name.csr && \
    openssl ca -batch -config /etc/nginx/tmp.cnf \
            -keyfile /etc/nginx/ca.key \
            -cert /etc/nginx/ca.pem \
            -extensions server_cert \
            -days 375 \
            -notext \
            -md sha256 \
            -in /etc/nginx/server.csr \
            -out /etc/nginx/server.pem


    /usr/share/wallarm-common/addnode --force  -u ${var.wallarm_deploy_username} -p '${var.wallarm_deploy_password}' -H ${var.wallarm_api_domain} --batch
    systemctl restart nginx

EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "wallarm" {
  name                = "${var.name_prefix}-wallarm-compute-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = "443"
  }
}

locals {
  distribution_policy_zones = [
    for i in range(var.az_count) : data.google_compute_zones.available.names[i]
  ]
}

resource "google_compute_region_instance_group_manager" "wallarm" {
  name = "${var.name_prefix}-wallarm"

  base_instance_name        = "wallarm"
  region                    = var.region
  distribution_policy_zones = local.distribution_policy_zones
  target_size               = var.az_count

  version {
    instance_template = google_compute_instance_template.wallarm.id
  }

  named_port {
    name = "http"
    port = "443"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.wallarm.id
    initial_delay_sec = 300
  }
}


# resource "google_compute_region_health_check" "wallarm_http" {
#   name = "${var.name_prefix}-wallarm-http-region-health-check"

#   timeout_sec        = 3
#   check_interval_sec = 5

#   http_health_check {
#     port = "80"
#     request_path = "/healthcheck"
#   }
# }

resource "google_compute_region_health_check" "wallarm_https" {
  name = "${var.name_prefix}-wallarm-https-region-health-check"

  timeout_sec        = 3
  check_interval_sec = 5

  http_health_check {
    port = "443"
    request_path = "/healthcheck"
  }
}


resource "google_compute_region_autoscaler" "wallarm" {
  name   = "${var.name_prefix}-wallarm-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.wallarm.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 120
    cpu_utilization {
      target = 0.4
    }
  }
}

# resource "google_compute_region_backend_service" "wallarm_http" {
#   name                  = "${var.name_prefix}-wallarm-backend-http-service"
#   port_name             = "http"
#   protocol              = "TCP"
#   load_balancing_scheme = "EXTERNAL"
#   #session_affinity      = "HTTP_COOKIE"

#   backend {
#     group = google_compute_region_instance_group_manager.wallarm.instance_group
#   }

#   health_checks = [
#     google_compute_region_health_check.wallarm_http.id
#   ]
# }

resource "google_compute_region_backend_service" "wallarm_https" {
  name                  = "${var.name_prefix}-wallarm-backend-https-service"
  port_name             = "https"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  #session_affinity      = "HTTP_COOKIE"

  backend {
    group = google_compute_region_instance_group_manager.wallarm.instance_group
  }

  health_checks = [
    google_compute_region_health_check.wallarm_https.id
  ]
}

resource "google_compute_address" "wallarm_nlb" {
  name         = "${var.name_prefix}-wallarm-nlb-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

# resource "google_compute_forwarding_rule" "wallarm_http" {
#   name            = "${var.name_prefix}-wallarm-http-forwarding-rule"
#   region          = var.region
#   ip_address      = google_compute_address.wallarm_nlb.self_link
#   ip_protocol     = "TCP"
#   port_range      = "80"
#   backend_service = google_compute_region_backend_service.wallarm_http.id
# }

resource "google_compute_forwarding_rule" "wallarm_https" {
  name            = "${var.name_prefix}-wallarm-https-forwarding-rule"
  region          = var.region
  ip_address      = google_compute_address.wallarm_nlb.self_link
  ip_protocol     = "TCP"
  port_range      = "443"
  backend_service = google_compute_region_backend_service.wallarm_https.id
}


# This example creates a self-signed certificate for a development
## environment.
## THIS IS NOT RECOMMENDED FOR PRODUCTION SERVICES.

resource "tls_private_key" "ca" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name         = "Example Inc. Root"
    organization        = "Example, Inc"
    organizational_unit = "Department of Certificate Authority"
    street_address      = ["5879 Cotton Link"]
    locality            = "Pirate Harbor"
    province            = "CA"
    country             = "US"
    postal_code         = "95559-1227"
  }

  validity_period_hours = 17520

  is_ca_certificate = true

  allowed_uses = ["cert_signing"]
}

resource "local_file" "ca_key" {
  content  = "${tls_private_key.ca.private_key_pem}"
  filename = "${path.module}/ca.key"
}

resource "local_file" "ca_crt" {
  content  = "${tls_self_signed_cert.ca.cert_pem}"
  filename = "${path.module}/ca.crt"
}

# server tls certificate

resource "tls_private_key" "server" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "server" {
  key_algorithm   = "${tls_private_key.server.algorithm}"
  private_key_pem = "${tls_private_key.server.private_key_pem}"

  subject {
    common_name         = "localhost"
    organization        = "Example, Inc"
    organizational_unit = "Tech Ops Dept"
  }

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]

  dns_names = ["localhost"]
}

resource "local_file" "server_key" {
  content  = "${tls_private_key.server.private_key_pem}"
  filename = "${path.module}/server.key"
}

resource "local_file" "server_crt" {
  content  = "${tls_self_signed_cert.server.cert_pem}"
  filename = "${path.module}/server.crt"
}
