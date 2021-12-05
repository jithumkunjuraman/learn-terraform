provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "prod-vpc" {
  cidr_block                       = "10.100.0.0/16"
  enable_dns_hostnames             = "true"
  assign_generated_ipv6_cidr_block = "true"
  tags = {
    "Name"        = "prod-vpc"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.100.0.0/24"
  tags = {
    Name          = "Prod-Private-Subnet"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name          = "Prod-Public-Subnet"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name          = "prod-vpc"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}


resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  #   route {
  #     ipv6_cidr_block        = "::/0"
  #     egress_only_gateway_id = aws_internet_gateway.gw.id
  #   }

  tags = {
    Name          = "prod-vpc"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}

resource "aws_route_table_association" "prod" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.prod.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name          = "prod-vpc"
    "billing"     = "jithu"
    "sub-billing" = "terraform"
  }
}

resource "aws_network_interface" "prod" {
  subnet_id       = aws_subnet.subnet-2.id
  private_ips     = ["10.100.1.5"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "eip" {
  vpc                       = true
  associate_with_private_ip = "10.100.1.5"
  network_interface         = aws_network_interface.prod.id
  depends_on                = [aws_internet_gateway.gw]
}

output "ip-attached" {
  value = aws_eip.eip.public_ip
}

resource "aws_instance" "myfirstinstance" {
  ami               = "ami-0860c9429baba6ad2"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name          = "jithus"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.prod.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'Jithus First Terraform!! Yay! > /var/www/html/index.html'
                EOF

  tags = {
    "Name"        = "terraform-learn-001"
    "billing"     = "jithu"
    "sub-billing" = "terraform-learn"
    "environment" = "stage"
  }
}