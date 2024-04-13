# ACS-Team Project

To Deploy the Terraform components.

first configure the aws access key in your terminal(if you are using vscode it is easier, go to /network folder and open a terminal and do this) - 

aws configure

<copy and paste your access key, press enter>

<copy and paste your secret access key, press enter>

<leave default all other valuse> 

aws configure set aws_session_token <your_aws_Session_token>



Now you can deploy terraform resouces to your aws account. 

terraform init 

terraform apply
