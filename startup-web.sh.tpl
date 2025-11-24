#!/bin/bash
set -e

export HOME=/root


apt-get update
apt-get install -y git ansible

git clone https://github.com/Breezy494/cis-91-project.git /opt/ansible

cd /opt/ansible

gcloud secrets versions access latest --secret="${vault_secret_id}" > /opt/ansible/.vault_pass

export ANSIBLE_CONFIG=/opt/ansible/ansible.cfg
ansible-playbook \
  -i "localhost," \
  --connection=local \
  --extra-vars "db_ip=${db_ip} db_pass_secret_id=${db_pass_secret_id}" \
 --vault-password-file /opt/ansible/.vault_pass \
  mediawiki.yml