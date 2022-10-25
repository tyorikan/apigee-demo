resource "google_compute_subnetwork" "gke-backend-network-1" {
  project       = module.host-project.project_id
  name          = "gke-backend-network-${var.gke_region_1}"
  network       = var.network
  region        = var.gke_region_1
  ip_cidr_range = var.gke_region_1_cidr_range

  secondary_ip_range {
    ip_cidr_range = var.gke_region_1_pod_cidr_range
    range_name    = "gke-pod-cidr-range-${var.gke_region_1}"
  }

  secondary_ip_range {
    ip_cidr_range = var.gke_region_1_service_cidr_range
    range_name    = "gke-service-cidr-range-${var.gke_region_1}"
  }
}

resource "google_compute_subnetwork" "gke-backend-network-2" {
  project       = module.host-project.project_id
  name          = "gke-backend-network-${var.gke_region_2}"
  network       = var.network
  region        = var.gke_region_2
  ip_cidr_range = var.gke_region_2_cidr_range

  secondary_ip_range {
    ip_cidr_range = var.gke_region_2_pod_cidr_range
    range_name    = "gke-pod-cidr-range-${var.gke_region_2}"
  }

  secondary_ip_range {
    ip_cidr_range = var.gke_region_2_service_cidr_range
    range_name    = "gke-service-cidr-range-${var.gke_region_2}"
  }
}

resource "google_compute_subnetwork" "proxy-only-subnet-1" {
  project       = module.host-project.project_id
  name          = "proxy-only-subnet-${var.gke_region_1}"
  network       = var.network
  region        = var.gke_region_1
  ip_cidr_range = var.gke_region_1_proxy_cidr_range
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "proxy-only-subnet-2" {
  project       = module.host-project.project_id
  name          = "proxy-only-subnet-${var.gke_region_2}"
  network       = var.network
  region        = var.gke_region_2
  ip_cidr_range = var.gke_region_2_proxy_cidr_range
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_firewall" "fw-allow-ssh" {
  project   = module.host-project.project_id
  name      = "fw-allow-ssh"
  network   = var.network
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "fw-allow-health-check" {
  project   = module.host-project.project_id
  name      = "fw-allow-health-check"
  network   = var.network
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] // Google Cloud healthcheck system
  target_tags   = ["allow-health-check"]
}

resource "google_compute_firewall" "fw-allow-proxy-only-subnet" {
  project   = module.host-project.project_id
  name      = "fw-allow-proxy-only-subnet"
  network   = var.network
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    #    ports    = ["80"]
  }

  source_ranges = [
    var.gke_region_1_proxy_cidr_range,
    var.gke_region_2_proxy_cidr_range,
    var.gke_region_1_cidr_range, // for test
    var.gke_region_2_cidr_range // for test
  ]
  #  target_tags   = ["allow-proxy-only-subnet"]
}

#resource "google_compute_firewall" "asm-multicluster-pods" {
#  project   = module.host-project.project_id
#  name      = "asm-multicluster-pods"
#  network   = var.network
#  direction = "INGRESS"
#  priority  = 900
#
#  allow { protocol = "tcp" }
#  allow { protocol = "udp" }
#  allow { protocol = "icmp" }
#  allow { protocol = "esp" }
#  allow { protocol = "ah" }
#  allow { protocol = "sctp" }
#
#  source_ranges = [var.gke_region_1_pod_cidr_range, var.gke_region_2_pod_cidr_range]
#
#  // TODO how should I set target tags dynamically?
#  target_tags = [
#    "gke-apigee-backend-asia-northeast1-c9791e7b-node",
#    "gke-apigee-backend-asia-northeast2-7ecba11b-node"
#  ]
#}