# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  name                = local.sql_instance_name
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false # not recommended for PROD

  settings {
    tier        = "db-custom-1-3840"
    user_labels = local.resource_labels

    ip_configuration {
      private_network = module.vpc.network_self_link
      ipv4_enabled    = false
    }
  }

  depends_on = [google_service_networking_connection.private_service_connection]
}

resource "google_sql_user" "datafusion" {
  instance = google_sql_database_instance.instance.id
  name     = "datafusion"
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 16
  special = false
  numeric = false
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "${local.sql_instance_name}-password"
  labels    = local.resource_labels
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
