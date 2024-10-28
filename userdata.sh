#!/bin/bash
sudo yum install ansible -y &> /opt/userdata.log
ansible-pull -i localhost, -U https://github.com/abhijeet4022/project-ansible.git main.yml -e component=rabbitmq &> /opt/userdata.log