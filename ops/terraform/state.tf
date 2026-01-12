terraform {
  backend "s3" {
    bucket       = "mpsm-terraform-state"
    key          = "vanilla-express-eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
