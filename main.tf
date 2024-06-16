terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
  }
}
#AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Create a VPC
resource "aws_vpc" "Demo" {
  cidr_block = "10.10.0.0/16"
  tags = {
    "Name" = "VPC_Production"
  }
}

######################################################## SUBNETS CREATION #####################################################
#Create a Private Subnet 
resource "aws_subnet" "Private_Subnet" {
  vpc_id = aws_vpc.Demo.id
  cidr_block = "10.10.70.0/24"
  availability_zone = "us-east-1"  
  tags = {
    "Name" = "Private Subnet"
  }
}

#Create a Public Subnet 
resource "aws_subnet" "Public_Subnet" {
  vpc_id = aws_vpc.Demo.id
  cidr_block = "10.10.80.0/24"
  availability_zone = "us-east-1"  
  map_public_ip_on_launch = true
  tags = {
    "Name" = "Public Subnet"
  }
}
######################################################## INTERNET GATEWAY CREATION ###############################################
# Create Public Internet Gateway
resource "aws_internet_gateway" "Public_igw" {
    vpc_id = aws_vpc.Demo.id
    tags = {
      "Name" = "Public Internet Gateway"
    } 
}

######################################################## NAT GATEWAY CREATION #####################################################
# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.Public_igw ]
  tags = {
    Name = "NAT_Elastic_IP_Gateway"
  }
}

# Create NAT Gateway and associate it with the Elastic IP and (Public) Subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.Public_Subnet.id
  tags = {
    "Name" = "Public_NAT_Gateway"
  }
}

######################################################## ROUTE TABLES CREATION #####################################################
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.Demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Public_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.Demo.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate route table with private subnet
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id = aws_subnet.Private_Subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

######################################################## NETWORK ACLs #####################################################
# Create Network ACLs
resource "aws_network_acl" "NACLS" {
  vpc_id = aws_vpc.Demo.id

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 65535
  }
}

# Associate NACLs with subnets
resource "aws_network_acl_association" "public" {
  subnet_id = aws_subnet.Public_Subnet.id
  network_acl_id = aws_network_acl.NACLS.id
}

resource "aws_network_acl_association" "private" {
  subnet_id = aws_subnet.Private_Subnet.id
  network_acl_id = aws_network_acl.NACLS.id
}




######################################################## SECURITY GROUPS CREATION #####################################################
# Create a Public Security Group
resource "aws_security_group" "Security_Public" {
  description = "Allow inbound external traffic"
  vpc_id = aws_vpc.Demo.id
  name = "EC2 Public Security Group"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["10.0.50.0/24"]
    from_port = 22
    to_port = 22
    description = "Allow SSH"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "EC2 Public Security Group"
  }
}

# Create a Private Security Group
resource "aws_security_group" "Security_Private" {
  description = "Allow inbound internal traffic"
  vpc_id = aws_vpc.Demo.id
  name = "EC2 Private Security Group"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["10.0.49.0/24"]
    from_port = 22
    to_port = 22
    description = "Allow SSH"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["10.0.49.0/24"]
    from_port = 5432
    to_port = 5434
    description = "Allow PostgreSQL range ports"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "EC2 Private Security Group"
  }
}

######################################################## EC2 INSTANCE FOR JUMP-BOX & POSTGERSQL14 #####################################################
#Create EC2 in Public Subnet
resource "aws_instance" "JUMP_BOX" {
  ami = "ami-06373f703eb245f45"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Security_Public.id,]
  subnet_id = aws_subnet.Public_Subnet_Prod.id

  tags = {
    Name = "Jump Box Instance"
  }
}

#Create EC2 in Private Subnet
resource "aws_instance" "POSTGRESQL" {
  ami = "ami-06373f703eb245f45"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Security_Private.id,]
  subnet_id = aws_subnet.Private_Subnet_Prod.id
  key_name = ""
  
    provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y postgresql14-server postgresql14",
      "sudo /usr/pgsql-14/bin/postgresql-14-setup initdb",
      "sudo systemctl start postgresql-14",
      "sudo systemctl enable postgresql-14"
    ]

    connection {
      type = "ssh"
      user = ""
      private_key = ""
      host = self.public_ip
    }
  }


  tags = {
    Name = "POSTGRESQL Instance"
  }
}

######################################################## CREATE AMI  #####################################################
resource "aws_ami_from_instance" "custom_ami" {
  name = "EC2-PostgresSQL-AMI"
  source_instance_id = aws_instance.POSTGRESQL.id
  depends_on = [aws_instance.POSTGRESQL]
}

output "ami_id" {
  value = aws_ami_from_instance.custom_ami.id
}

