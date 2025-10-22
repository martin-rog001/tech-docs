#!/bin/bash
# Setup script for AWS EC2 Ansible provisioning

echo "=== AWS EC2 Ansible Setup ==="

# Install Ansible AWS collection
echo "Installing Ansible AWS collection..."
ansible-galaxy collection install amazon.aws

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Configure AWS CLI (optional)
echo ""
echo "Configure AWS credentials:"
echo "1. Run: aws configure"
echo "2. Or set environment variables:"
echo "   export AWS_ACCESS_KEY_ID='your-access-key'"
echo "   export AWS_SECRET_ACCESS_KEY='your-secret-key'"
echo "   export AWS_DEFAULT_REGION='us-east-1'"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials"
echo "2. Create an SSH key pair in AWS EC2 console"
echo "3. Update variables in playbook.yml"
echo "4. Run: ansible-playbook playbook.yml"
