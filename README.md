# AWS_K8s_Deployment
Instructions to deploy K8s on AWS EC2 using Jenkins, Terraform and Ansible

1. Make sure that you have Jenkins running and create a pipeline job
2. Add the GitHub repo and point to the Jenkinsfile
3. Make sure the AWS cli has the necessary setup
4. Run the pipeline

Please note: 
1. The inventory file will be generated from the Terraform output
2. At the end of the pipeline it will delete everything (money saver as this is a test system)