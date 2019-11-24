provider "aws" {
  version    = "~> 2.0"
  region     = var.aws_default_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

provider "acme" {
  server_url = var.acme_server_url
}

### NETWORKING
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "boucan-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "boucan-ig"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)

  tags = {
    Name = "boucan-subnet"
  }
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main.id]

  tags = {
    Name = "boucan-acl"
  }
}

# TODO: make restrictive
resource "aws_network_acl_rule" "allow_all_in" {
  rule_number    = 100
  rule_action    = "allow"
  egress         = false
  from_port      = 0
  to_port        = 65535
  protocol       = -1
  cidr_block     = var.internet_cidr_block
  network_acl_id = aws_network_acl.main.id
}

resource "aws_network_acl_rule" "allow_all_out" {
  rule_number    = 100
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 65535
  protocol       = -1
  cidr_block     = var.internet_cidr_block
  network_acl_id = aws_network_acl.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "boucan-rt"
  }
}

resource "aws_route" "egress" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

### Security Groups 

resource "aws_security_group" "main" {
  name        = "boucan-sg"
  description = "A Generica Security Group for a Boucan Server"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "dashboard_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 8080
  to_port           = 8080
}

resource "aws_security_group_rule" "dashboard_ingress_https" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 8443
  to_port           = 8443
}

resource "aws_security_group_rule" "ssh_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_external_cidr_block
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group_rule" "wireguard_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = var.wireguard_port
  to_port           = var.wireguard_port
}


resource "aws_security_group_rule" "wireguard_ingress_udp" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = var.wireguard_port
  to_port           = var.wireguard_port
}

resource "aws_security_group_rule" "http_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 80
  to_port           = 80
}

resource "aws_security_group_rule" "https_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 443
  to_port           = 443
}

resource "aws_security_group_rule" "dns_tcp_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 53
  to_port           = 53
}

resource "aws_security_group_rule" "dns_udp_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 53
  to_port           = 53
}

resource "aws_security_group_rule" "all_outbound_tcp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 65535
}

resource "aws_security_group_rule" "all_outbound_udp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "udp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 65535
}

resource "aws_security_group_rule" "all_outbound_icmp" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  protocol          = "icmp"
  cidr_blocks       = [var.internet_cidr_block]
  from_port         = 0
  to_port           = 8
}

### EC2(s)

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "null_resource" "save_ssh_locally" {
  triggers = {
    public_key = tls_private_key.ssh.public_key_openssh
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.ssh.private_key_pem}' >> data/key.pem && chown 600 data/key.pem"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "boucan-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  associate_public_ip_address = true

  tags = {
    Name = "boucan-server"
  }
}

### Environment + Secrets 

# jwt secret is generated on the server via API_SECRET
# ssl can be disabled (and probably is) in order to use the docker-compose hostname "proxy"
data "template_file" "dns_env" {
  template = <<EOT
API_URL=https://web:8443
EOT

}

data "template_file" "http_env" {
  template = <<EOT
API_URL=https://web:8443
EOT

}

#### Database 

resource "random_pet" "db_database" {
  length    = 2
  separator = "_"
}

resource "random_pet" "db_username" {
  length    = 2
  separator = "-"
}

resource "random_string" "db_password" {
  length  = 32
  special = false
}

#### do not use single quotes
data "template_file" "db_env" {
  template = <<EOT
POSTGRES_DB=${random_pet.db_database.id}
POSTGRES_USER=${random_pet.db_username.id}
POSTGRES_PASSWORD=${random_string.db_password.result}
EOT

}

#### Proxy 

#### do not use single quotes
data "template_file" "web_env" {
  template = <<EOT
SSL_ENABLED=1
INSECURE_LISTEN_PORT=8080
SECURE_LISTEN_PORT=8443
API_BACKEND_PROTO=http
API_BACKEND_HOST=boucan
API_BACKEND_PORT=8080
DEBUG_CONF=1
EOT

}

#### Broadcast 

resource "random_string" "broadcast_password" {
  length  = 24
  special = false
}

#### do not use single quotes
data "template_file" "broadcast_env" {
  template = <<EOT
REDIS_PASSWORD=${random_string.broadcast_password.result}
REDIS_MASTER_HOST=redis
EOT

}

#### Api 

resource "random_string" "api_secret_key" {
  length  = 32
  special = false
}

data "template_file" "api_env" {
  template = <<EOT
API_ENV=prod
API_SECRET_KEY=${random_string.api_secret_key.result}
API_SERVER_NAME=boucan
API_CORS_ORIGINS=http://${var.dns_dashboard_sub}.${var.dns_root}:8080,http://${var.dns_sub}.${var.dns_root}:8080,http://${aws_instance.main.public_ip}:8080,https://${var.dns_dashboard_sub}.${var.dns_root}:8443,http://${var.dns_sub}.${var.dns_root}:8443,http://${aws_instance.main.public_ip}:8443
DB_DRIVER=postgresql
DB_HOST=db
DB_PORT=5432
DB_USER=${random_pet.db_username.id}
DB_PASSWORD=${random_string.db_password.result}
DB_DATABASE=${random_pet.db_database.id}
BROADCAST_ENABLED=1
BROADCAST_DRIVER=redis
BROADCAST_HOST=broadcast
BROADCAST_PORT=6379
BROADCAST_PASSWORD=${random_string.broadcast_password.result}
BROADCAST_PATH=0
SEED_USER_0_EMAIL=${var.admin_email}
SEED_USER_0_PASSWORD=${var.admin_password}
SEED_USER_0_SUPERUSER=1
SEED_DNS_SERVER_0_NAME=default
SEED_ZONE_0_IP=${aws_instance.main.public_ip}
SEED_ZONE_0_DOMAIN=${var.dns_sub}.${var.dns_root}
EOT

}

### Configuration
resource "null_resource" "server_configure" {
  triggers = {
    server_id     = aws_instance.main.id
    api_env       = data.template_file.api_env.rendered
    db_env        = data.template_file.db_env.rendered
    web_env       = data.template_file.web_env.rendered
    broadcast_env = data.template_file.broadcast_env.rendered
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${data.template_file.api_env.rendered}' | sudo tee /etc/boucan/env/api.env > /dev/null",
      "echo '${data.template_file.db_env.rendered}' | sudo tee /etc/boucan/env/db.env > /dev/null",
      "echo '${data.template_file.web_env.rendered}' | sudo tee /etc/boucan/env/web.env > /dev/null",
      "echo '${data.template_file.broadcast_env.rendered}' | sudo tee /etc/boucan/env/broadcast.env > /dev/null",
      "echo '${data.template_file.dns_env.rendered}' | sudo tee /etc/boucan/env/dns.env > /dev/null",
      "echo '${data.template_file.http_env.rendered}' | sudo tee /etc/boucan/env/http.env > /dev/null",
      "TOKEN=$(/opt/boucan/boucan-compose/makejwt.py -S '${random_string.api_secret_key.result}' -n default -d 30 | cut -d ':' -f2-); echo API_TOKEN=$TOKEN | sudo tee -a /etc/boucan/env/http.env > /dev/null",
      "TOKEN=$(/opt/boucan/boucan-compose/makejwt.py -S '${random_string.api_secret_key.result}' -n default -d 30 | cut -d ':' -f2-); echo API_TOKEN=$TOKEN | sudo tee -a /etc/boucan/env/dns.env > /dev/null"

    ]
  }
}

### Route53 + TLS

# TODO: remove this and use default zone created by aws and change to data

data "aws_route53_zone" "main" {
  name = "${var.dns_root}."
}

resource "aws_route53_record" "a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.dns_sub}.${var.dns_root}"
  type    = "A"
  ttl     = "5"
  records = [aws_instance.main.public_ip]
}

resource "aws_route53_record" "a_dash" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.dns_dashboard_sub}.${var.dns_root}"
  type    = "A"
  ttl     = "5"
  records = [aws_instance.main.public_ip]
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "acme@${var.dns_sub}.${var.dns_root}"
}

resource "tls_private_key" "base_cert_private_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "base_req" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.base_cert_private_key.private_key_pem
  dns_names       = ["${var.dns_sub}.${var.dns_root}"]

  subject {
    common_name = "${var.dns_sub}.${var.dns_root}"
  }
}

resource "acme_certificate" "base_certificate" {
  account_key_pem         = acme_registration.reg.account_key_pem
  certificate_request_pem = tls_cert_request.base_req.cert_request_pem

  recursive_nameservers = ["${var.upstream_dns_server}:53"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_ACCESS_KEY_ID       = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY   = var.aws_secret_access_key
      AWS_DEFAULT_REGION      = var.aws_default_region
      AWS_HOSTED_ZONE_ID      = data.aws_route53_zone.main.zone_id
      AWS_PROPAGATION_TIMEOUT = 300
    }
  }
}

resource "tls_private_key" "dashboard_cert_private_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "dashboard_req" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.dashboard_cert_private_key.private_key_pem
  dns_names       = ["${var.dns_dashboard_sub}.${var.dns_root}"]

  subject {
    common_name = "${var.dns_dashboard_sub}.${var.dns_root}"
  }
}

# used by nginx proxy (dashboard)
resource "acme_certificate" "dashboard_certificate" {
  account_key_pem         = acme_registration.reg.account_key_pem
  certificate_request_pem = tls_cert_request.dashboard_req.cert_request_pem

  recursive_nameservers = ["${var.upstream_dns_server}:53"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_ACCESS_KEY_ID       = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY   = var.aws_secret_access_key
      AWS_DEFAULT_REGION      = var.aws_default_region
      AWS_HOSTED_ZONE_ID      = data.aws_route53_zone.main.zone_id
      AWS_PROPAGATION_TIMEOUT = 300
    }
  }
}

# A root tls cert cannot be generated (base_certificate) while this exists
resource "aws_route53_record" "bdns_ns" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.dns_sub}.${var.dns_root}"
  type    = "NS"
  ttl     = "5"
  records = ["${var.dns_sub}.${var.dns_root}."]
  depends_on = [
    acme_certificate.base_certificate,
    acme_certificate.dashboard_certificate,
  ]
}

resource "null_resource" "setup_tls" {
  triggers = {
    server_id       = aws_instance.main.id
    private_key_pem = tls_private_key.dashboard_cert_private_key.private_key_pem
    certificate_pem = acme_certificate.dashboard_certificate.certificate_pem
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/letsencrypt/live/boucan.proxy.docker",
      "echo '${replace(
        tls_private_key.dashboard_cert_private_key.private_key_pem,
        "\n",
        "\\n",
      )}' | sudo tee /etc/letsencrypt/live/boucan.proxy.docker/privkey.pem > /dev/null",
      "echo '${replace(
        acme_certificate.dashboard_certificate.certificate_pem,
        "\n",
        "\\n",
      )}' | sudo tee /etc/letsencrypt/live/boucan.proxy.docker/fullchain.pem > /dev/null",
      "echo '${replace(
        acme_certificate.dashboard_certificate.issuer_pem,
        "\n",
        "\\n",
      )}' | sudo tee -a /etc/letsencrypt/live/boucan.proxy.docker/fullchain.pem > /dev/null",
    ]
  }
}

resource "null_resource" "restart_service" {
  triggers = {
    server_id       = aws_instance.main.id
    api_env         = data.template_file.api_env.rendered
    db_env          = data.template_file.db_env.rendered
    web_env         = data.template_file.web_env.rendered
    broadcast_env   = data.template_file.broadcast_env.rendered
    private_key_pem = tls_private_key.private_key.private_key_pem
    certificate_pem = acme_certificate.dashboard_certificate.certificate_pem
  }

  connection {
    host        = aws_instance.main.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    agent       = false # change to true if agent is required
  }

  provisioner "remote-exec" {
    inline = [
      "echo '127.0.0.1 ${var.dns_dashboard_sub}.${var.dns_root}' | sudo tee -a /etc/hosts",
      "echo '127.0.0.1 ${var.dns_sub}.${var.dns_root}' | sudo tee -a /etc/hosts",
      "sudo hostnamectl set-hostname ${var.dns_dashboard_sub}.${var.dns_root}",
      "cd /opt/boucan/boucan-compose && sudo git pull origin master",
      "sudo systemctl enable boucan-compose",
      "sudo systemctl restart boucan-compose",
    ]
  }
}

