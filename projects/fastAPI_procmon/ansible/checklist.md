# FastAPI Deployment Readiness Checklist

## ❌ Pre-Deployment Tasks (Required)

### 1. SSH Key Setup
- [ ] Generate SSH key pair
- [ ] Add public key to EC2 instance (16.170.161.51)
- [ ] Test SSH connection: `ssh -i ~/.ssh/key ubuntu@16.170.161.51`
- [ ] Add private key to Jenkins credentials (`ec2-server-ssh-key`)

### 2. Domain Configuration
- [ ] Point domain `ameed.xyz` to IP `16.170.161.51`
- [ ] Verify DNS propagation: `nslookup ameed.xyz`

### 3. Initial Server Setup
```bash
# Run the initial setup playbook FIRST
cd projects/fastAPI_procmon/ansible
ansible-playbook initial-setup.yml -i inventory.ini
```

### 4. SSL Certificate Setup
```bash
ssh ubuntu@16.170.161.51
sudo certbot --nginx -d ameed.xyz -d www.ameed.xyz
```

#### Manual fixes
##### 🔐 Certbot SSL Certificates via Route 53

* Ran Certbot using DNS challenge:

  ```bash
  sudo certbot certonly --dns-route53 -d ameed.xyz -d www.ameed.xyz
  ```
* Certificates were saved to:

  * `/etc/letsencrypt/live/ameed.xyz/fullchain.pem`
  * `/etc/letsencrypt/live/ameed.xyz/privkey.pem`

---

##### 🌐 Nginx Configuration for HTTPS

* Created custom nginx config via Ansible Jinja template (`nginx.conf.j2`) with:

  * HTTP → HTTPS redirect
  * SSL certificates from Certbot
  * Reverse proxy to FastAPI container
* Verified that rendered config was deployed to:

  ```bash
  /etc/nginx/sites-available/fastapi
  ```

---

##### 🔁 Reloaded Nginx

```bash
sudo nginx -t && sudo systemctl reload nginx
```
### Testing
### 1. Test Ansible Connectivity
```bash
cd projects/fastAPI_procmon/ansible
ansible ec2_servers -m ping -i inventory.ini
```

### 2. Test Docker on Server
```bash
ssh ubuntu@16.170.161.51 "docker run hello-world"
```

### 3. Test Nginx Configuration
```bash
ssh ubuntu@16.170.161.51 "sudo nginx -t"
```

### 4. Test SSL Certificate
```bash
ssh ubuntu@16.170.161.51 "sudo openssl x509 -in /etc/ssl/certs/ameed.de.pem -text -noout"
```

## 🚀 Deployment Commands

### Manual Deployment
```bash
cd projects/fastAPI_procmon/ansible

# Deploy specific image
ansible-playbook deploy.yml \
  -e "image_name=amid68/fastapi-procmon:development-8" \
  -e "deployment_environment=dev" \
  -i inventory.ini
```
