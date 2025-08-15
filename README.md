# Terraform + Ansible for Flask, netcat, certbot

Glue that I wrote to quickly spin up a GCP VM instance for:
- Flask
- netcat listener
- HTTPS support using certbot

A basic hello world is used for the Flask app, the intention is to edit the code over SSH and have the change reloaded for quick testing.

## Setup

1. Create a project on Google Cloud
2. `gcloud auth application-default login`
3. Generate SSH key.

```shell
ssh-keygen -t rsa -b 4096 -f id_rsa
```

4. Update project info and region for your GCP account in `main.tf`.

```
# update this for your google account
locals {
    project = "YOUR-PROJECT-ID"
    region = "asia-southeast1"
    zone = "asia-southeast1-c"
    username = "YOUR USERNAME ON THE HOST"
}
```

5. `terraform apply`
6. Update the ansible files for your configuration.

Set the IP address for your GCP VM in `ansible/inventory.ini`

```
[web]
; VM instance IP here
127.0.0.1 
```

Update username in `ansible/deploy.yml` with your GCP VM username:

```
- name: Install nginx, gunicorn, Flask
  hosts: all
  # remote_user: root
  remote_user: YOUR USERNAME HERE
```

Set your certificate email and domain in `ansible/roles/certbot/defaults/main.yml`.

> ![IMPORTANT]
> Make sure that you have an A record that points your domain to the VM's IP address.

```
letsencrypt_email: "user@domain.com"
letsencrypt_domain: "yourdomain.com"
```

Set `server_name` in `ansible/roles/nginx/templates/default.conf` to your domain.

```
server {
    listen 80;
    # update server name with your domain
    server_name yourdomain.com;
```

7. Run the ansible playbook.
```
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --key-file id_rsa 
```
