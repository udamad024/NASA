# ACS-Team Project

1. To Deploy the Terraform components.

   first configure the aws access key in your terminal(if you are using vscode it is easier, go to /network folder and open a terminal and do this) - 

   aws configure

   <copy and paste your access key, press enter>

   <copy and paste your secret access key, press enter>

   <leave default all other valuse> 

   aws configure set aws_session_token <your_aws_Session_token>

   update ./network/config.tf and ./webserver/config.tf to change the S3 bucket name where the terraform statefile will be saved
 
   also update ./webserver/main.tf to change the S3 bucket name under data "terraform_remote_state"

   Now you can deploy terraform resouces to your aws account. 

   terraform init 

   terraform apply


2. To run the Ansible code, issue the following command:

   ansible-playbook -i aws_ec2.yaml  playbook.yaml
