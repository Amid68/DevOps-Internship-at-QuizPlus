#!/bin/bash
# test-deployment-readiness.sh
# Run this script to verify your deployment is ready

set -e  # Exit on any error

SERVER_IP="16.170.161.51"
DOMAIN="ameed.xyz"
SSH_KEY="~/.ssh/dev-fastapi-key.pem"  # Update this path
ANSIBLE_DIR="./"

echo "🔍 Testing FastAPI Deployment Readiness..."
echo "=========================================="

# Test 1: SSH connectivity
echo "1. Testing SSH connectivity..."
if ssh -i $SSH_KEY -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "echo 'SSH connection successful'"; then
    echo "   ✅ SSH connection works"
else
    echo "   ❌ SSH connection failed"
    echo "   📝 Solution: Run ssh-copy-id or check your key path"
    exit 1
fi

# Test 2: Check if server is prepared
echo "2. Checking server preparation..."
SSH_CMD="ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$SERVER_IP"

# Check Docker
if $SSH_CMD "docker --version" >/dev/null 2>&1; then
    echo "   ✅ Docker is installed"
else
    echo "   ❌ Docker not installed"
    echo "   📝 Solution: Run the initial-setup.yml playbook first"
    exit 1
fi

# Check Nginx
if $SSH_CMD "nginx -version" >/dev/null 2>&1; then
    echo "   ✅ Nginx is installed"
else
    echo "   ❌ Nginx not installed"
    echo "   📝 Solution: Run the initial-setup.yml playbook first"
    exit 1
fi

# Check if ubuntu user can run Docker
if $SSH_CMD "docker ps" >/dev/null 2>&1; then
    echo "   ✅ Ubuntu user can run Docker"
else
    echo "   ❌ Ubuntu user cannot run Docker"
    echo "   📝 Solution: Add ubuntu user to docker group and logout/login"
    exit 1
fi

# Test 3: Check SSL certificate
echo "3. Checking SSL certificate..."
if $SSH_CMD "sudo test -f /etc/ssl/certs/$DOMAIN.pem"; then
    echo "   ✅ SSL certificate exists"
elif $SSH_CMD "sudo test -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem"; then
    echo "   ✅ Let's Encrypt certificate exists"
else
    echo "   ❌ No SSL certificate found"
    echo "   📝 Solution: Generate SSL certificate (see deployment checklist)"
fi

# Test 4: Domain DNS resolution
echo "4. Testing domain resolution..."
if nslookup $DOMAIN | grep -q $SERVER_IP; then
    echo "   ✅ Domain $DOMAIN resolves to $SERVER_IP"
else
    echo "   ⚠️  Domain $DOMAIN does not resolve to $SERVER_IP"
    echo "   📝 Note: This may still work for direct IP deployment"
fi

# Test 5: Check Ansible setup
echo "5. Testing Ansible configuration..."
if [ -d "$ANSIBLE_DIR" ]; then
    cd $ANSIBLE_DIR
    
    # Test Ansible connectivity
    if ansible ec2_servers -m ping -i inventory.ini >/dev/null 2>&1; then
        echo "   ✅ Ansible can connect to servers"
    else
        echo "   ❌ Ansible cannot connect to servers"
        echo "   📝 Solution: Check inventory.ini and SSH key paths"
        exit 1
    fi
else
    echo "   ❌ Ansible directory not found: $ANSIBLE_DIR"
    exit 1
fi

# Test 6: Check ports
echo "6. Testing port accessibility..."
if nc -z -w5 $SERVER_IP 22; then
    echo "   ✅ Port 22 (SSH) is accessible"
else
    echo "   ❌ Port 22 (SSH) is not accessible"
    echo "   📝 Solution: Check security groups and firewall"
fi

if nc -z -w5 $SERVER_IP 443; then
    echo "   ✅ Port 443 (HTTPS) is accessible"
else
    echo "   ❌ Port 443 (HTTPS) is not accessible"
    echo "   📝 Solution: Configure firewall to allow HTTPS"
fi

echo ""
echo "🎉 Deployment Readiness Test Complete!"
echo ""
