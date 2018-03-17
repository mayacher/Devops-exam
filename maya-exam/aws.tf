provider "aws" {
  #region     = "eu-west-1"
}


### networking configuration for vpc ###
variable "vpc_cidr_block" {
  default = "172.16.0.0/16"
}

# setting vpc
resource "aws_vpc" "terraform_stage" {
  cidr_block = "${var.vpc_cidr_block}"

  tags {
    Name = "terraform_stage"
  }
}



### vars  ###

variable "sub" {
  default = [
    { 
      subnet="frontend"
      instances = 2
      availability-zone = "eu-west-1c"
    },
    {
      subnet = "backend"
      instances = 2
      availability-zone = "eu-west-1c"
    },
    {
      subnet = "vpn"
      instances = 1
      availability-zone = "eu-west-1c"
    },
    {
      subnet = "public"
      availability-zone = "eu-west-1b"
    },
  ]
}

variable "key-pair" {
  default = "maya-personal"
}

variable "ami" {
  default = "ami-1b791862"
}

variable "instance_type" {
  default = "t2.micro"
}




### create subnets  ###
resource "aws_subnet" "terraform_stage" {
  vpc_id = "${aws_vpc.terraform_stage.id}"
  count  = "${length(var.sub)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block,8,count.index)}" 
  availability_zone  = "${lookup(var.sub[count.index], "availability-zone")}"
  tags {
    Name = "${lookup(var.sub[count.index], "subnet")}" 
  }
}


### create security groups ###

resource "aws_security_group" "vpn-sg" {
  name  = "vpn-sg"
  tags {
     Name  = "vpn-sg"
  }
  description  = "access to vpn"	
  vpc_id      =  "${aws_vpc.terraform_stage.id}"
  
  ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb-sg" {      
  name  = "alb-sg"   
   tags {
     Name  = "alb-sg"
  }                         
  description =  "sg for alb" 
  vpc_id      =  "${aws_vpc.terraform_stage.id}"
                
  ingress  {                                  
  from_port   = 80                            
  to_port     = 80                            
  protocol    = "tcp"                         
  cidr_blocks = ["0.0.0.0/0"]                 
  }                                           
}                                             

resource "aws_security_group" "backend-sg" {              
  name  = "backend-sg"   
   tags {
     Name  = "backend-sg"
  }                                 
  description =  "backend-sg"                         
  vpc_id      =  "${aws_vpc.terraform_stage.id}"      
                                                      
  ingress  {                                                 
  from_port   = 0                                          
  to_port     = 65535                                      
  protocol    = "tcp"                                      
  security_groups = ["${aws_security_group.vpn-sg.id}"]    
  }                                                                                                 
}

resource "aws_security_group" "frontend-sg" {
  name  = "frontend-sg"
   tags {
     Name  = "frontend-sg"
  }                      
  description  = "frontend-sg"
  vpc_id       =  "${aws_vpc.terraform_stage.id}"           
  
  ingress  {                                                      
    from_port   = 0                                                   
    to_port     = 65535                                                   
    protocol    = "tcp"                                                   
    security_groups = ["${aws_security_group.vpn-sg.id}"]    
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups =  ["${aws_security_group.backend-sg.id}"]                                                                       
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups =  ["${aws_security_group.alb-sg.id}"]
  }                        
}                                                                      



### create instances ###


resource "aws_instance" "frontend" {
  count         = "${lookup(var.sub[0], "instances")}"
  subnet_id     = "${element(aws_subnet.terraform_stage.*.id, 0)}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.frontend-sg.id}"]
  key_name      = "${var.key-pair}"
  tags    {
    Name      = "${lookup(var.sub[0], "subnet")}-${count.index}"
  }
}


resource "aws_instance" "backend" {                                     
  count         = "${lookup(var.sub[1], "instances")}"                   
  subnet_id     = "${element(aws_subnet.terraform_stage.*.id, 1)}"
  ami           = "${var.ami}"                                        
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.backend-sg.id}"]                                             
  key_name      = "${var.key-pair}"
  tags    {
    Name      = "${lookup(var.sub[1], "subnet")}-${count.index}"       
  }
}

resource "aws_instance" "vpn" {                                     
  count         = "${lookup(var.sub[2], "instances")}"                  
  subnet_id     = "${element(aws_subnet.terraform_stage.*.id, 2)}"
  ami           = "${var.ami}"                                       
  instance_type = "${var.instance_type}"
  associate_public_ip_address  = "True"  
  vpc_security_group_ids = ["${aws_security_group.vpn-sg.id}"]                                        
  key_name      = "${var.key-pair}" 
  tags    {
    Name     = "${lookup(var.sub[2], "subnet")}-${count.index}"     
  }                    
}


### create alb ###

# internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform_stage.id}"

  tags {
    Name = "terra-gw"
  }
}

# public routing table
resource "aws_route_table" "r-gt" {
  vpc_id = "${aws_vpc.terraform_stage.id}" 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_route"
  }
}



### attach instances to alb ###

resource "aws_lb_target_group" "terraform-tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.terraform_stage.id}"
}

# target group
resource "aws_lb_target_group_attachment" "terraform-tg-attachment" {
  count            = "${lookup(var.sub[0], "instances")}"
  target_group_arn = "${aws_lb_target_group.terraform-tg.arn}"
  target_id        = "${element(aws_instance.frontend.*.id, count.index)}"
  port             = 80
}                                           


# alb
resource "aws_lb" "alb-terraform" {
  name            = "terraform-lb"
  internal        = false
  security_groups = ["${aws_security_group.alb-sg.id}"]
  subnets         = ["${element(aws_subnet.terraform_stage.*.id, 0)}", "${element(aws_subnet.terraform_stage.*.id, 3)}"]
}

# listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = "${aws_lb.alb-terraform.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.terraform-tg.arn}"
    type             = "forward"
  }
}



### rds ###

resource "aws_security_group" "rds-sg" { 
  name = "rds-sg"    
   tags {
     Name  = "rds-sg"
  }                         
  vpc_id  =  "${aws_vpc.terraform_stage.id}"

  ingress  {                                                       
  from_port   = 3306                                                       
  to_port     = 3306                                                       
  protocol    = "tcp"                                                      
  security_groups = ["${aws_security_group.backend-sg.id}"]        
  }
}                                                               


# deal with db subnet group error
resource "random_string" "subg-name" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# db subnet group 
resource "aws_db_subnet_group" "terra-rds-sub" {
  name       = "rds-subnet-${random_string.subg-name.result}"
  subnet_ids = ["${element(aws_subnet.terraform_stage.*.id, 1)}","${element(aws_subnet.terraform_stage.*.id, 3)}"]

  tags {
    Name = "rds-subnet"
  }
}

# db instance
resource "aws_db_instance" "terra-rds" {
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.medium"
  name                 = "mydba"
  username             = "admin"
  password             = "Kd6B`-py"
  db_subnet_group_name = "${aws_db_subnet_group.terra-rds-sub.name}"
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
  final_snapshot_identifier  = "${aws_db_subnet_group.terra-rds-sub.name}-final-snapshot"
}


# the end
