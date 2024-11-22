# Create an EC2 instance
# AWS_ACCESS_KEY = xxxx MUST NEVER DO THIS
# AWS_SECRET_KEY = xxxx MUST NEVER DO THIS
# Syntax often used in HCL is key = value
# Where to create - provide the provider

provider "aws" {
  # which region to use to create infrastructure
  region = var.aws_region
}

# Create an app Security Group
resource "aws_security_group" "ps_app_sg" {
  name        = "tech264-priyan-tf-app-sg-2"
  description = "Allow SSH and HTTP traffic"


}

# NSG Rules
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_22" {

  security_group_id = aws_security_group.ps_app_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_5000" {

  security_group_id = aws_security_group.ps_app_sg.id
  from_port         = 5000
  ip_protocol       = "tcp"
  to_port           = 5000
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_5000"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {

  security_group_id = aws_security_group.ps_app_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_out_all" {

  security_group_id = aws_security_group.ps_app_sg.id
  ip_protocol       = "All"
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_Out_all"
  }
}

# Create db security group
resource "aws_security_group" "ps_db_sg" {
  name        = "tech264-priyan-tf-db-sg"
  description = "Allow SSH and MySQL traffic"


}
# NSG Rules
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_22" {

  security_group_id = aws_security_group.ps_db_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_3306" {

  security_group_id = aws_security_group.ps_db_sg.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_5000"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_out_all" {

  security_group_id = aws_security_group.ps_db_sg.id
  ip_protocol       = "All"
  cidr_ipv4         = var.allowed_cidr_blocks
  tags = {
    Name = "Allow_Out_all"
  }
}

# Which service/resources to create
resource "aws_instance" "app_instance" {
  # Which AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
  ami = var.ami_id
  # What type of instance to launch - t2.micro
  instance_type = var.instance_type
  # Add a public IP to this instance
  associate_public_ip_address = true
  # Security group
  vpc_security_group_ids = [aws_security_group.ps_db_sg.id]
  # SSH Key pair 
  key_name = var.key_name
  # Name the service/resource we create
  tags = {
    Name = "tech264-priyan-tf-java-db-instance"
  }
}
# Which service/resources to create
resource "aws_instance" "app_instance" {
  # Which AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
  ami = var.ami_id
  # What type of instance to launch - t2.micro
  instance_type = var.instance_type
  # Add a public IP to this instance
  associate_public_ip_address = true
  # Security group
  vpc_security_group_ids = [aws_security_group.ps_app_sg.id]
  # SSH Key pair 
  key_name = var.key_name
  # Depends on DB VM
  depends_on = [ aws_instance.app_instance ]
  # Name the service/resource we create
  tags = {
    Name = "tech264-priyan-tf-java-app-instance"
  }
}

