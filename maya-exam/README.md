Set env  variables before run terraform:
     export AWS_ACCESS_KEY_ID="your_access_key"
     export AWS_SECRET_ACCESS_KEY="your_secret_key"
     export AWS_DEFAULT_REGION="aws_region"

aws regions
us-east-1 
us-east-2 
us-west-1 
us-west-2 
ca-central-1 
eu-central-1 
eu-west-1 
eu-west-2 
eu-west-3 
ap-northeast-1 
ap-northeast-2 
ap-northeast-3 
ap-southeast-1 
ap-southeast-2 
ap-south-1 
sa-east-1

Run this commands to run terraform
$  terraform init
$  terraform plan
$  terraform apply

After finish checking the env
$ terraform destroy
