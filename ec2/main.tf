provider "aws" {
  region = "ap-south-1"
  shared_credentials_file =  "/Users/jithu.kunjuraman/.aws/credentials"
}


resource "aws_instance" "myfirstinstance" {
    ami = "ami-0860c9429baba6ad2"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"

    tags = {
      "Name" = "terraform-learn-001"
      "billing" = "jithu"
      "sub-billing" = "terraform-learn"
      "environment" = "stage"
    }
  
}