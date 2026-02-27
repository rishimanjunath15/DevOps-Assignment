# Jenkins CI/CD Setup Guide for dhee-devops

## Quick Start

**Jenkins URL**: http://13.201.88.252:8080  
**Instance ID**: i-07247739adf11962b  
**Instance Type**: t3.micro (Free Tier)  
**Region**: ap-south-1 (Mumbai)

---

## Step 1: Access Jenkins Initial Setup

1. **Open Jenkins in browser**: http://13.201.88.252:8080
2. **Wait 1-2 minutes** for Jenkins to fully initialize
3. You'll see the "Unlock Jenkins" page asking for initial admin password

### Get Initial Admin Password (via SSH)

```bash
# SSH to Jenkins instance
ssh -i your-key.pem ec2-user@13.201.88.252

# Get the password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Copy the entire long string
```

### Alternative: Check EC2 System Logs (AWS Console)

1. Go to EC2 Dashboard
2. Select instance `i-07247739adf11962b`
3. Click "Instance Settings" → "System Log"
4. Look for Jenkins initialization output

---

## Step 2: Complete Jenkins Setup Wizard

1. **Paste Initial Password** and click "Continue"
2. **Install Suggested Plugins** (recommended for standard setup)
3. **Create First Admin User**:
   - Username: `admin`
   - Password: `your-secure-password`
   - Full Name: `Admin User`
   - Email: `your-email@example.com`
4. **Configure Jenkins URL**: Keep default `http://jenkins.example.com:8080/`
5. **Save and Finish**

---

## Step 3: Install Required Plugins

Navigate to **Manage Jenkins** → **Manage Plugins** → **Available** tab

### Search and install these plugins:

1. **Pipeline** (usually pre-installed)
2. **Git**
3. **GitHub**
4. **Docker**
5. **Docker Pipeline**
6. **Amazon EC2**
7. **SonarQube Scanner**
8. **Trivy** (if available) or add manually
9. **AWS SDK** / **AWS Steps**

**After installation**, restart Jenkins:
- **Manage Jenkins** → **Restart Jenkins**
- Wait 2-3 minutes for restart

---

## Step 4: Configure System Settings

### 4.1 Configure Git

1. Go to **Manage Jenkins** → **Tools**
2. Find **Git installations**
3. Verify path: `/usr/bin/git`

### 4.2 Configure Docker

1. Go to **Manage Jenkins** → **Tools**
2. Find **Docker installations**
3. Verify path: `/usr/bin/docker`

### 4.3 Configure SonarQube Server

1. Go to **Manage Jenkins** → **System Configuration**
2. Find **SonarQube servers**
3. Click **Add SonarQube**
4. **Name**: `SonarQube`
5. **Server URL**: `http://YOUR_SONARQUBE_IP:9000`
6. **Server authentication token**: Get from SonarQube (create if needed)

---

## Step 5: Add Credentials

### 5.1 Add GitHub Personal Access Token

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. **Kind**: Username with password
4. **Username**: `github-token`
5. **Password**: Your GitHub Personal Access Token
6. **ID**: `github-credentials`
7. **Description**: `GitHub API Token`

### 5.2 Add Docker Hub Credentials

1. Click **Add Credentials** again
2. **Kind**: Username with password
3. **Username**: Your Docker Hub username
4. **Password**: Your Docker Hub token
5. **ID**: `docker-hub-credentials`
6. **Description**: `Docker Hub Credentials`

### 5.3 Add AWS Credentials (Optional - EC2 IAM role handles this)

Jenkins EC2 already has IAM role attached with ECR/ECS permissions. But if needed:

1. Click **Add Credentials**
2. **Kind**: AWS Credentials
3. **Access Key ID**: Your AWS access key
4. **Secret Access Key**: Your AWS secret key
5. **ID**: `aws-credentials`

---

## Step 6: Create Pipeline Jobs

### 6.1 Create Dev Pipeline Job

1. **New Item**
2. **Item name**: `dhee-devops-dev`
3. **Type**: `Pipeline`
4. **Click OK**

### Configure Dev Pipeline:

**General Tab:**
- ☑ **GitHub project**: `https://github.com/yourusername/dhee-devops-project`
- ☑ **Build Triggers → GitHub hook trigger**: Enable

**Advanced:**
- ☑ **Pipeline script from SCM**
- **SCM**: Git
  - Repositories URL: `https://github.com/yourusername/dhee-devops-project.git`
  - Credentials: Select `github-credentials`
  - Branch: `*/dev`
- **Script Path**: `Jenkinsfile-dev`

### 6.2 Create Staging Pipeline Job

**Repeat above but:**
- **Item name**: `dhee-devops-staging`
- **Branch**: `*/staging`
- **Script Path**: `Jenkinsfile-staging`

### 6.3 Create Production Pipeline Job

**Repeat above but:**
- **Item name**: `dhee-devops-prod`
- **Branch**: `*/prod`  or `*/main`
- **Script Path**: `Jenkinsfile-prod`

**⚠️ Additional Config for Prod:**
- **Additional behaviors** → **Wipe out repository & force clone**
- **Poll SCM** (Optional): `H H * * 0` (weekly safety check)

---

## Step 7: Configure GitHub Webhooks

### Add Jenkins webhook to GitHub repository:

1. Go to GitHub repo **Settings** → **Webhooks**
2. Click **Add webhook**
3. **Payload URL**: `http://13.201.88.252:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: 
   - ☑ Push events
   - ☑ Pull requests
   - ☑ Pull request reviews
6. **Active**: ☑
7. **Add webhook**

### Test webhook:

1. Go back to **Recent Deliveries**
2. Should see green checkmark (✓)
3. If red, click to see error details

---

## Step 8: Environment Variables Setup

Update Jenkinsfiles with your values:

1. **Edit each Jenkinsfile** (dev/staging/prod):
   - Replace `655024857157` with your AWS Account ID (it's already correct)
   - Replace `YOUR_SONARQUBE_HOST` with actual SonarQube URL
   - Replace `yourusername` with Docker Hub username

2. **Push changes** to GitHub:
   ```bash
   git add Jenkinsfile-*
   git commit -m "Update Jenkins pipeline environment variables"
   git push origin dev
   ```

---

## Step 9: Manual Test Run

### Test Dev Pipeline:

1. Go to `dhee-devops-dev` job
2. Click **Build Now**
3. Watch build progress in **Console Output**
4. Check logs for any errors

### Expected flow:
```
✓ Checkout
✓ SonarQube Analysis
✓ Build Backend
✓ Build Frontend
✓ Trivy Scan
✓ Push to ECR
✓ Push to Docker Hub
✓ Deploy to ECS
✓ Verify Deployment
```

---

## Troubleshooting

### Issue: Docker permission denied

**Fix**:
```bash
ssh ec2-user@13.201.88.252
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: Git clone fails

1. Check GitHub credentials in Jenkins
2. Verify GitHub token has `repo` scope
3. Test token: `curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user`

### Issue: ECR push fails

Jenkins EC2 IAM role already has permissions. If failing:
```bash
ssh ec2-user@13.201.88.252
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin 655024857157.dkr.ecr.ap-south-1.amazonaws.com
```

### Issue: ECS deployment not updating

1. Verify task has been registered in ECS
2. Check ECS service for desired vs running count
3. Review ECS task logs: `aws ecs describe-task-definition --task-definition prod-backend`

### Issue: Jenkins not accessible

1. Check security group allows port 8080:
   ```bash
   aws ec2 describe-security-groups --group-ids sg-0835e1e704f756f93 --region ap-south-1
   ```

2. Check Jenkins service status:
   ```bash
   ssh ec2-user@13.201.88.252
   sudo systemctl status jenkins
   sudo tail -100 /var/log/jenkins/jenkins.log
   ```

---

## Next Steps

1. ✅ Access Jenkins: http://13.201.88.252:8080
2. ✅ Complete setup wizard
3. ✅ Install plugins
4. ✅ Add credentials
5. ✅ Create 3 pipeline jobs
6. ✅ Configure GitHub webhooks
7. ✅ Run manual test
8. 🚀 Push code to GitHub and watch pipelines auto-trigger

---

## Architecture Overview

```
GitHub (Webhook Trigger)
    ↓
Jenkins EC2 (t3.micro, 13.201.88.252:8080)
    - Git Checkout
    - SonarQube Analysis
    - Docker Build
    ↓
ECR (AWS Container Registry)
Docker Hub (yourusername)
    ↓
ECS Deployment (Dev/Staging/Prod Clusters)
    ↓
ALB (Application Load Balancer)
    ↓
Frontend/Backend Services Running
```

---

## CI/CD Pipeline Stages

### Development Pipeline (Auto-triggers on `dev` branch):
- **Goal**: Quick feedback for developers
- **Scan Level**: HIGH vulnerabilities
- **Deployment**: Auto-deploy to dev ECS
- **Duration**: ~5-10 minutes

### Staging Pipeline (Auto-triggers on `staging` branch):
- **Goal**: Pre-production validation
- **Scan Level**: MEDIUM,HIGH vulnerabilities  
- **Deployment**: Auto-deploy to staging ECS
- **Tests**: Includes smoke tests
- **Duration**: ~7-12 minutes

### Production Pipeline (Triggers on `main`/`prod` branch):
- **Goal**: Safe, controlled production deployment
- **Scan Level**: HIGH,CRITICAL vulnerabilities only
- **Deployment**: **Requires manual approval**
- **Tests**: Full health checks + rollback ready
- **Duration**: ~8-15 minutes (plus approval wait)

---

## File Structure

```
DevOps-Assignment/
├── Jenkinsfile-dev       ← Dev pipeline
├── Jenkinsfile-staging   ← Staging pipeline
├── Jenkinsfile-prod      ← Production pipeline (with approval stage)
├── backend/
│   └── Dockerfile
├── frontend/
│   └── Dockerfile
└── infrastructure/
    └── aws/
        └── modules/
            └── jenkins_ec2/  ← Jenkins Terraform module
```

---

## Security Notes

- ✅ Jenkins EC2 has restricted IAM role (ECR push/pull, ECS update only)
- ✅ Security group allows SSH from 0.0.0.0/0 (restrict to your IP in production)
- ✅ Credentials stored encrypted in Jenkins
- ✅ JNLP agents use VPC CIDR block (10.0.0.0/16)
- ⚠️ Use Elastic IP (13.201.88.252) for stable webhook endpoint
- ⚠️ Consider restricting SSH to your office IP: Edit sg-0835e1e704f756f93

---

## Cleanup (Delete Jenkins)

To remove Jenkins and save costs:

```bash
cd infrastructure/aws/envs/dev
terraform destroy -auto-approve
```

This will destroy:
- Jenkins EC2 instance
- Elastic IP
- IAM role/policies
- Security group

---

**Created**: $(date)  
**Jenkins Version**: Will show after initial setup  
**Terraform Module**: infrastructure/aws/modules/jenkins_ec2/  
**Contact**: DevOps Team
