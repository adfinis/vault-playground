terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.7"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 3.5"
    }
  }
}
