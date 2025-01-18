variable "name" {
  description = "Name of the repository"
}

variable "description" {
  description = "Description of the repository"
}

variable "visibility" {
  description = "Visibility (public | private)"
}

variable "template" {
  type = object({
    owner      = string
    repository = string
  })
  description = "GitHub Template"
  default     = null
}

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

resource "github_repository" "repo" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  auto_init   = true

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = false
  delete_branch_on_merge = true

  has_issues      = true
  has_discussions = true
  has_projects    = false
  has_wiki        = false

  dynamic "template" {
    for_each = var.template == null ? [] : [1]
    content {
      owner      = var.template.owner
      repository = var.template.repository
    }
  }
}

resource "github_branch_protection" "main" {
  count = var.visibility == "private" ? 0 : 1

  repository_id = github_repository.repo.node_id

  pattern                 = "main"
  enforce_admins          = true
  require_signed_commits  = false
  allows_deletions        = false
  allows_force_pushes     = false
  required_linear_history = true
}

output "repository_url" {
  description = "The URL of the created GitHub repository"
  value       = github_repository.repo.html_url
}
