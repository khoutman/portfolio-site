resource "kubernetes_namespace" "sandox-namespace" {
  metadata {
    name = "sandbox"

    labels = {
      name = "sandbox"
      environment = "sandbox"
    }
  }
}

resource "kubernetes_namespace" "production-namespace" {
  metadata {
    name = "production"

    labels = {
      name = "production"
      environment = "production"
    }
  }
}

resource "kubernetes_namespace" "dev-namespace" {
  metadata {
    name = "dev"

    labels = {
      name = "dev"
      environment = "dev"
    }
  }
}
