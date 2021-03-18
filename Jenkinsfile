pipeline {
    agent any

    stages {
        stage('Create AWS EC2 Instances') {
            steps {
                echo 'Run Terraform to Create EC2 Instances'
                cd Terraform
                terraform init
                terraform apply --auto-approve
            }
        }
        stage('Deploy K8s to AWS EC2 Instance') {
            steps {
                echo 'Deploy K8s with Ansible'
                cp inventory ../Ansible
                cd ../Ansible
                ansible-playbook create_user.yaml -k -K
                ansible-playbook package_install.yaml -k -K
                ansible-playbook cluster_init.yaml -k -K
                ansible-playbook worker.yaml -k -K
            }
        }
        stage('Destory AWS EC2 Instances') {
            steps {
                echo 'Destroy AWS EC2 Instance with Terraform'
                cd ../Terraform
                terraform destroy --auto-approve
            }
        }
    }
}
