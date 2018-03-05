# Devops Exercise

###### Intro
- This exercise will allow us to view your abilities to learn terraform and use AWS and is designed to be simple and finished in less than 2-3 hours

###### Guidelines
1. You should use **terraform** to build the solution
1. Code and data should be separated so values such as VPC subnet mask are easily configurable 
1. Fork this repository and submit a pull request once you are finished
1. Consider best practices while implementing the solution
1. The solution should work out of the box and any dependencies should be documented as pre-requisites if they are needed to complete the deployment
1. You can use any external resource or code example you wish as long as you can explain them
1. if anything is unclear feel free to contact me for clarifications
1. ** Keep it simple**
1. if you think anything should be changed in the requirements or implemented differently add a remarks file and explain what you think should be done differently and why


## Ready?

During this exercise you will create a simple AWS VPC  with 5 ec2 instances, 1 RDS and an ALB

##### Requirements

- 1 VPC for the whole project
- Inside the VPC we should have 3 subnets:
-Frontend
-Backend
-VPN
- launch 2 instances in the frontend subnet and 2 in the backend - use any debian AMI that you wish
- launch an additional debian instance in the vpn subnet
- don't assign public ips to any of the instances except the vpn instance
- allow access from the vpn instance to all instances on all ports
- don't allow any access from the frontend to the backend except on port 8080
- allow access from the backend instances to the RDS
- point the ALB to the frontend instances on port 80
- Create the RDS
- create Cloudwatch alerts for metrics you think are relevant to monitor on all the instances


##### Bonus points

If you find this exercise interesting and would like to do some more exercising here are some additional bonus exercises 
Implementing will take much longer since automating all the installation are complex but it's fun :)
but definitely not required to pass the test

- Install Nginx on the frontend instances and create a proxy to the backend instances
- install nodejs on the backend servers and run a simple hello world application
- install openvpn on the vpn server and allow access to it only using openssl
- add autoscaling to the frontend and backend servers
- use spot instances 







