#!/bin/bash
set -e

export HOME=/root

apt-get update
apt-get install -y git ansible

if [ -d "/opt/ansible/.git" ]; then
  echo "Ansible repository found. Pulling latest changes."
  cd /opt/ansible
  git pull
else
  echo "Cloning Ansible repository."
  git clone https://github.com/Breezy494/cis-91-project.git /opt/ansible
fi

cd /opt/ansible

ansible-playbook \
  -i "localhost," \
  --connection=local \
  --extra-vars "db_ip=${db_private_ip} db_pass_secret_id=${db_pass_secret_id}" \
  mediawiki.yml

cd /
