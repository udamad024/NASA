terraform {
  backend "s3" {
    bucket = "lab2tfstate"             // Bucket from where to GET Terraform State
    key    = "Non-prod/network/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                     // Region where bucket created
  }
}
