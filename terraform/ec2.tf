resource "aws_instance" "ec2" { 
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = local.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data     = <<EOF
        #!/bin/bash

        ###########JENKINS###############
        yum update -y
        sudo wget -O /etc/yum.repos.d/jenkins.repo \
        https://pkg.jenkins.io/redhat-stable/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
        yum upgrade -y
        amazon-linux-extras install java-openjdk11 -y
        yum install jenkins git jq -y

        ###########DOCKER################
        yum install -y docker
        systemctl start docker
        systemctl enable docker
        usermod -aG docker jenkins
        systemctl enable jenkins
        systemctl start jenkins

        ############KUBECTLandHELM##########
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh

        #############INSTALL MINIKUBE###########
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        install minikube-linux-amd64 /usr/local/bin/minikube
        usermod -s /bin/bash jenkins
        echo -e "123\n123" | sudo passwd jenkins
        su - jenkins -c "minikube start --disk-size 10000mb"

EOF
  iam_instance_profile = aws_iam_instance_profile.profile.name
  tags = {
    Name = "Jenkins"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }
}
