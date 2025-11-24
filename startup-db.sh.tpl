#!/bin/bash
set -e

export HOME=/root


apt-get update
apt-get install -y git ansible


git clone https://github.com/Breezy494/cis-91-project.git /opt/ansible

cd /opt/ansible


gcloud secrets versions access latest --secret="${vault_secret_id}" > /opt/ansible/.vault_pass

ansible-playbook \
  -i "localhost," \
  --connection=local \
  --extra-vars "backup_bucket_name=${backup_bucket_name} db_root_secret_id=${db_root_secret_id}" \
  --vault-password-file /opt/ansible/.vault_pass \
  install_db.yml