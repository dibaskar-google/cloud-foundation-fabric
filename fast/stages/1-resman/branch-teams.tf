/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Team stage resources.

# TODO(ludo): add support for CI/CD

module "branch-prod-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.teams ? 1 : 0
  parent = "organizations/${var.organization.id}"
  name   = "Production"
  iam = {
    "roles/logging.admin"                  = [module.branch-prod-sa.0.iam_email]
    "roles/owner"                          = [module.branch-prod-sa.0.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-prod-sa.0.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-prod-sa.0.iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-prod-sa.0.iam_email]
  }
  tag_bindings = {
    environment = try(
      module.organization.tag_values["${var.tag_names.environment}/production"].id, null
    )
  }
}

module "branch-prod-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.teams ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-teams-0"
  display_name = "Terraform resman teams service account."
  prefix       = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "branch-prod-gcs" {
  source        = "../../../modules/gcs"
  count         = var.fast_features.teams ? 1 : 0
  project_id    = var.automation.project_id
  name          = "prod-teams-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-prod-sa.0.iam_email]
  }
}

module "branch-dev-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.teams ? 1 : 0
  parent = "organizations/${var.organization.id}"
  name   = "Development"
  iam = {
    "roles/logging.admin"                  = [module.branch-dev-sa.0.iam_email]
    "roles/owner"                          = [module.branch-dev-sa.0.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-dev-sa.0.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-dev-sa.0.iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-dev-sa.0.iam_email]
  }
  tag_bindings = {
    environment = try(
      module.organization.tag_values["${var.tag_names.environment}/development"].id, null
    )
  }
}

module "branch-dev-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.teams ? 1 : 0
  project_id   = var.automation.project_id
  name         = "dev-teams-0"
  display_name = "Terraform resman teams service account."
  prefix       = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "branch-dev-gcs" {
  source        = "../../../modules/gcs"
  count         = var.fast_features.teams ? 1 : 0
  project_id    = var.automation.project_id
  name          = "dev-teams-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dev-sa.0.iam_email]
  }
}

module "branch-prod-team-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-prod-folder.0.id
  name     = each.value.descriptive_name
  iam = {
    "roles/owner"                          = [module.branch-prod-team-sa[each.key].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-prod-team-sa[each.key].iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-prod-team-sa[each.key].iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-prod-team-sa[each.key].iam_email]
  }
  iam_by_principals = each.value.iam_by_principals == null ? {} : each.value.iam_by_principals
}

# TODO: move into team's own IaC project

module "branch-prod-team-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id   = var.automation.project_id
  name         = "prod-teams-${each.key}-0"
  display_name = "Terraform team ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      compact([try(module.branch-prod-team-sa-cicd[each.key].iam_email, null)]),
      (
        each.value.impersonation_principals == null
        ? []
        : [for g in each.value.impersonation_principals : g]
      )
    )
  }
}

module "branch-prod-team-gcs" {
  source        = "../../../modules/gcs"
  for_each      = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id    = var.automation.project_id
  name          = "prod-teams-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-prod-team-sa[each.key].iam_email]
  }
}

module "branch-dev-team-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-dev-folder.0.id
  name     = each.value.descriptive_name
  iam = {
    "roles/owner"                          = [module.branch-dev-team-sa[each.key].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-dev-team-sa[each.key].iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-dev-team-sa[each.key].iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-dev-team-sa[each.key].iam_email]
  }
  iam_by_principals = each.value.iam_by_principals == null ? {} : each.value.iam_by_principals
}

# TODO: move into team's own IaC project

module "branch-dev-team-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id   = var.automation.project_id
  name         = "dev-teams-${each.key}-0"
  display_name = "Terraform team ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      compact([try(module.branch-prod-team-sa-cicd[each.key].iam_email, null)]),
      (
        each.value.impersonation_principals == null
        ? []
        : [for g in each.value.impersonation_principals : g]
      )
    )
  }
}

module "branch-dev-team-gcs" {
  source        = "../../../modules/gcs"
  for_each      = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id    = var.automation.project_id
  name          = "dev-teams-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dev-team-sa[each.key].iam_email]
  }
}


# per-team folders where project factory SAs can create projects

module "branch-prod-teams-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-prod-team-folder[each.key].id
  # naming: environment descriptive name
  name = "team-a"
  # environment-wide human permissions on the whole teams environment
  iam_by_principals = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = (
      local.branch_optional_sa_lists.pf-dev
    )
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = local.branch_optional_sa_lists.pf-prod
    "roles/logging.admin"                  = local.branch_optional_sa_lists.pf-prod
    "roles/resourcemanager.folderAdmin"    = local.branch_optional_sa_lists.pf-prod
    "roles/resourcemanager.projectCreator" = local.branch_optional_sa_lists.pf-prod
    "roles/resourcemanager.folderViewer"   = local.branch_optional_r_sa_lists.pf-prod
    "roles/viewer"                         = local.branch_optional_r_sa_lists.pf-prod
  }
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/teams"].id, null
    )
  }
}

module "branch-dev-teams-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-dev-team-folder[each.key].id
  # naming: environment descriptive name
  name = "team-a"
  # environment-wide human permissions on the whole teams environment
  iam_by_principals = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = (
      local.branch_optional_sa_lists.pf-dev
    )
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = local.branch_optional_sa_lists.pf-dev
    "roles/logging.admin"                  = local.branch_optional_sa_lists.pf-dev
    "roles/resourcemanager.folderAdmin"    = local.branch_optional_sa_lists.pf-dev
    "roles/resourcemanager.projectCreator" = local.branch_optional_sa_lists.pf-dev
    "roles/resourcemanager.folderViewer"   = local.branch_optional_r_sa_lists.pf-dev
    "roles/viewer"                         = local.branch_optional_r_sa_lists.pf-dev
  }
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/teams"].id, null
    )
  }
}