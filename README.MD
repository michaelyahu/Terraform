# **AWS infrastructure overview**

### The structure of the AWS infrastructure ###  

### OVERVIEW
   Automate the setup and management of a fundamental AWS infrastructure. Here's a simplified breakdown of what this does:  

* VPC Creation:  
  ```python 
  
   Creates a Virtual Private Cloud (VPC) named VPC_Production with a CIDR block of 10.10.0.0/16.

* Availability Zone:  
    ```python
     
    The infrastructure will only be built in one single Availability zone 'us-east-1'.

* Subnets Creation:  
    ```python

    Private Subnet: Creates a private subnet named Private Subnet within the VPC with a CIDR block of 10.10.70.0/24 in the availability zone eu-west-2a.  

    Public Subnet: Creates a public subnet named Public Subnet within the VPC with a CIDR block of 10.10.80.0/24 in the availability zone eu-west-2a and enables public IP assignment on launch.  

* Internet Gateway:  
    ```python
    Creates an internet gateway named Public Platoon Internet Gateway and attaches it to the VPC.  

* NAT Gateway:  
    ```python
    Allocates an Elastic IP (EIP) for the NAT gateway.  
    Creates a NAT gateway named Public_NAT_Gateway, associates it with the allocated EIP, and places it in the public subnet.  

* Route Tables:  
    ```python
    Public Route Table: Creates a route table with a route to the internet (0.0.0.0/0) via the internet gateway and associates it with the public subnet.  

    Private Route Table: Creates a route table with a route to the internet (0.0.0.0/0) via the NAT gateway and associates it with the private subnet.  

* Network ACLs (NACLs)  
    ```python
    Network ACLs act as a firewall for controlling traffic in and out of one or more subnets. set up NACLs to allow SSH and all outbound traffic.  

* Security Groups:  
    ```python
    Public Security Group: Allows SSH traffic from within the public subnet and allows all outbound traffic.  

    Private Security Group: Allows SSH and PostgreSQL traffic from within the private subnet and allows all outbound traffic.  

* EC2 Instances:  
    ```python
    Jump Box Instance: Creates an EC2 instance in the public subnet using a specified AMI, with security group Security_Public.

    PostgreSQL Instance: Creates an EC2 instance in the private subnet using a specified AMI, with security group Security_Private, and installs PostgreSQL 14. The instance is configured via a remote-exec provisioner using SSH.  

* AMI Creation:  
    ```python
    Creates an Amazon Machine Image (AMI) from the PostgreSQL EC2 instance and outputs the AMI ID.  

