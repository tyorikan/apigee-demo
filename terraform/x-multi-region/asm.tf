locals {
  fleet_service_account   = "service-${var.project_number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "fleet-cluster-access-binding" {
  members = ["serviceAccount:${local.fleet_service_account}"]
  project = var.project_id
  role    = "roles/anthosservicemesh.serviceAgent"
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
