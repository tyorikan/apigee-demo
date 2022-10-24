locals {
  release_channel         = "STABLE"
  networking_mode         = "VPC_NATIVE"
  gke_service_account     = "service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
  gke_api_service_account = "${var.project_number}@cloudservices.gserviceaccount.com"
  fleet_service_account   = "service-${var.project_number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "container-host-service-agent-binding" {
  members = ["serviceAccount:${local.gke_service_account}"]
  project = module.host-project.project_id
  role    = "roles/container.hostServiceAgentUser"
}

resource "google_project_iam_binding" "compute-network-user-binding" {
  members = ["serviceAccount:${local.gke_service_account}", "serviceAccount:${local.gke_api_service_account}"]
  project = module.host-project.project_id
  role    = "roles/compute.networkUser"
}

resource "google_project_iam_binding" "fleet-cluster-access-binding" {
  members = ["serviceAccount:${local.fleet_service_account}"]
  project = var.project_id
  role    = "roles/anthosservicemesh.serviceAgent"
}

resource "google_container_cluster" "gke-autopilot-1" {
  depends_on = [
    google_compute_subnetwork.gke-backend-network-1,
    google_project_iam_binding.container-host-service-agent-binding,
    google_project_iam_binding.compute-network-user-binding
  ]

  name             = "apigee-backend-${var.gke_region_1}"
  enable_autopilot = true
  location         = var.gke_region_1
  networking_mode  = local.networking_mode
  network          = module.shared-vpc.self_link
  subnetwork       = google_compute_subnetwork.gke-backend-network-1.self_link

  release_channel {
    channel = local.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke-backend-network-1.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke-backend-network-1.secondary_ip_range[1].range_name
  }

  private_cluster_config {
    enable_private_endpoint = false
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "19:00" // GMT
    }
  }

  resource_labels = {
    mesh_id = "proj-${var.project_number}"
  }
}

resource "google_container_cluster" "gke-autopilot-2" {
  depends_on = [
    google_compute_subnetwork.gke-backend-network-2,
    google_project_iam_binding.container-host-service-agent-binding,
    google_project_iam_binding.compute-network-user-binding
  ]

  name             = "apigee-backend-${var.gke_region_2}"
  enable_autopilot = true
  location         = var.gke_region_2
  networking_mode  = local.networking_mode
  network          = module.shared-vpc.self_link
  subnetwork       = google_compute_subnetwork.gke-backend-network-2.self_link

  release_channel {
    channel = local.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke-backend-network-2.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke-backend-network-2.secondary_ip_range[1].range_name
  }

  private_cluster_config {
    enable_private_endpoint = false
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "19:00" // GMT
    }
  }

  resource_labels = {
    mesh_id = "proj-${var.project_number}"
  }
}

resource "google_gke_hub_membership" "membership-1" {
  membership_id = "${google_container_cluster.gke-autopilot-1.name}-membership"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.gke-autopilot-1.id}"
    }
  }
  provider = google-beta
}

resource "google_gke_hub_membership" "membership-2" {
  membership_id = "${google_container_cluster.gke-autopilot-2.name}-membership"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.gke-autopilot-2.id}"
    }
  }
  provider = google-beta
}

resource "google_gke_hub_feature" "feature" {
  provider = google-beta

  name     = "servicemesh"
  location = "global"
}

#module "asm-apigee-backend-1" {
#  source              = "terraform-google-modules/kubernetes-engine/google//modules/asm"
#  project_id          = var.project_id
#  cluster_name        = google_container_cluster.gke-autopilot-1.name
#  cluster_location    = google_container_cluster.gke-autopilot-1.location
#  multicluster_mode   = "connected"
#  enable_cni          = true
#  fleet_id            = var.project_id
#}
#
#module "asm-apigee-backend-2" {
#  source              = "terraform-google-modules/kubernetes-engine/google//modules/asm"
#  project_id          = var.project_id
#  cluster_name        = google_container_cluster.gke-autopilot-2.name
#  cluster_location    = google_container_cluster.gke-autopilot-2.location
#  multicluster_mode   = "connected"
#  enable_cni          = true
#  fleet_id            = var.project_id
#}
#
#data "google_client_config" "default" {}
#
#provider "kubernetes" {
#  host                   = "https://${google_container_cluster.gke-autopilot-1.endpoint}"
#  token                  = data.google_client_config.default.access_token
#  cluster_ca_certificate = base64decode(google_container_cluster.gke-autopilot-1.master_auth.0.cluster_ca_certificate)
#  alias                  = "apigee-backend-cluster-1"
#}
#
#provider "kubernetes" {
#  host                   = "https://${google_container_cluster.gke-autopilot-2.endpoint}"
#  token                  = data.google_client_config.default.access_token
#  cluster_ca_certificate = base64decode(google_container_cluster.gke-autopilot-2.master_auth.0.cluster_ca_certificate)
#  alias                  = "apigee-backend-cluster-2"
#}
