# big query dataset setup
# resource "google_bigquery_dataset" "dataset" {
#     dataset_id = var.dataset_id
#     location   = var.region
#     description = "Dataset for ${var.project_id}"
#     labels = {
#         environment = var.environment
#         project     = var.project_id
#     }
# }