# AWS EC2 Provisioning with Ansible

Ansible playbooks to provision, manage, and terminate EC2 instances on AWS.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Ansible** installed (2.9+)
3. **AWS CLI** configured (optional but recommended)
4. **SSH Key Pair** created in AWS EC2

## Setup

### 1. Install Dependencies

```bash
# Install Ansible AWS collection
ansible-galaxy collection install amazon.aws

# Install Python dependencies
pip install -r requirements.txt
```

Or run the setup script:
```bash
chmod +x setup.sh
./setup.sh
```

### 2. Configure AWS Credentials

**Option 1: AWS CLI (Recommended)**
```bash
aws configure
```

**Option 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID='your-access-key'
export AWS_SECRET_ACCESS_KEY='your-secret-key'
export AWS_DEFAULT_REGION='us-east-1'
```

**Option 3: Ansible Vault (Most Secure)**
```bash
# Create encrypted file
ansible-vault create aws-credentials.yml

# Add your credentials:
# aws_access_key: YOUR_ACCESS_KEY
# aws_secret_key: YOUR_SECRET_KEY
```

### 3. Create SSH Key Pair

In AWS EC2 Console:
1. Go to EC2 > Network & Security > Key Pairs
2. Create a new key pair
3. Download the `.pem` file
4. Save it to `~/.ssh/` and set permissions:
   ```bash
   chmod 400 ~/.ssh/your-key-pair.pem
   ```

### 4. Update Configuration

Edit `playbook.yml` and update:
- `key_name`: Your AWS key pair name
- `ami_id`: AMI ID for your region (see AMI IDs section below)
- `aws_region`: Your AWS region
- Other variables as needed

## Usage

### Provision EC2 Instance

```bash
ansible-playbook playbook.yml
```

This will:
- Create a security group
- Launch an EC2 instance
- Install NGINX
- Create `instance-info.txt` with connection details
- Create `ec2-inventory.ini` for use with other playbooks

### List Instances

```bash
ansible-playbook list-instances.yml
```

### Manage Instance (Start/Stop/Reboot)

```bash
# Stop instance
ansible-playbook manage-instance.yml -e "action=stopped"

# Start instance
ansible-playbook manage-instance.yml -e "action=running"

# Reboot instance
ansible-playbook manage-instance.yml -e "action=restarted"
```

### Terminate Instance

```bash
ansible-playbook terminate.yml
```

### Connect to Instance

After provisioning, use the SSH command from `instance-info.txt`:

```bash
ssh -i ~/.ssh/your-key-pair.pem ubuntu@<public-ip>
```

## AMI IDs (Ubuntu 20.04 LTS)

Update the `ami_id` variable based on your region:

| Region       | AMI ID                  |
|--------------|-------------------------|
| us-east-1    | ami-0c55b159cbfafe1f0  |
| us-west-1    | ami-0d382e80be7ffdae5  |
| us-west-2    | ami-0d1cd67c26f5fca19  |
| eu-west-1    | ami-0dad359ff462124ca  |
| eu-central-1 | ami-0502e817a62226e03  |
| ap-south-1   | ami-0c1a7f89451184c8b  |

Find current AMI IDs: https://cloud-images.ubuntu.com/locator/ec2/

## Instance Types

Common instance types:
- `t2.micro` - 1 vCPU, 1 GB RAM (Free tier eligible)
- `t2.small` - 1 vCPU, 2 GB RAM
- `t2.medium` - 2 vCPU, 4 GB RAM
- `t3.micro` - 2 vCPU, 1 GB RAM
- `t3.small` - 2 vCPU, 2 GB RAM

## Security Groups

The default security group allows:
- SSH (port 22) from anywhere
- HTTP (port 80) from anywhere
- HTTPS (port 443) from anywhere

**Security Warning:** For production, restrict SSH access to your IP:
```yaml
- proto: tcp
  ports: 22
  cidr_ip: YOUR_IP/32  # Replace with your IP
```

## Files Generated

After running the playbook:
- `instance-info.txt` - Instance details and connection info
- `ec2-inventory.ini` - Ansible inventory file for the instance

## Customization

### Custom User Data Script

Edit the `user_data` section in `playbook.yml`:

```yaml
user_data: |
  #!/bin/bash
  apt-get update
  apt-get install -y your-packages
  # Your custom commands
```

### Using Variables File

Create `vars.yml` from `vars-example.yml`:
```bash
cp vars-example.yml vars.yml
# Edit vars.yml with your settings
```

Run with variables file:
```bash
ansible-playbook playbook.yml -e @vars.yml
```

## Troubleshooting

### "No module named boto3"
```bash
pip install boto3 botocore
```

### "The security token included in the request is invalid"
- Check your AWS credentials
- Ensure they have proper permissions
- Try reconfiguring: `aws configure`

### "Invalid KeyPair.NotFound"
- Create a key pair in AWS EC2 console
- Update `key_name` in playbook.yml

### Cannot connect via SSH
- Check security group allows port 22
- Verify key file permissions: `chmod 400 ~/.ssh/key.pem`
- Wait a few minutes for instance initialization

## Cost Warning

EC2 instances incur charges. Remember to:
- Use `t2.micro` for free tier eligibility
- Terminate instances when not in use: `ansible-playbook terminate.yml`
- Monitor your AWS billing dashboard

## Additional Resources

- [Ansible AWS Documentation](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS Free Tier](https://aws.amazon.com/free/)

## License

MIT
