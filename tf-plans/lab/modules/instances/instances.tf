resource "google_compute_instance" "tf-instance-1" {
  project      = var.project_id
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = "tf-vpc-024061"
    subnetwork = "subnet-01"
    access_config {}
  }

  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT

  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  project      = var.project_id
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = "tf-vpc-024061"
    subnetwork = "subnet-02"
    access_config {}
  }

  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT

  allow_stopping_for_update = true
}

# resource "google_compute_instance" "tf-instance-3" {
#   project      = var.project_id
#   name         = "tf-instance-758091"
#   machine_type = "e2-standard-2"
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-12"
#     }
#   }

#   network_interface {
#     network = "default"
#     access_config {}
#   }

#   metadata_startup_script = <<-EOT
#         #!/bin/bash
#     EOT

#   allow_stopping_for_update = true 
# }