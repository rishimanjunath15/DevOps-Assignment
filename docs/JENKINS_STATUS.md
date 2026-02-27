# Jenkins Setup - Current Status & Next Steps

**Date**: February 27, 2026  
**Status**: Jenkins EC2 instance created, initialization in progress

---

##  Jenkins Instance Details

| Property | Value |
|----------|-------|
| **Instance ID** | `i-09440e039f8557c49` |
| **Public IP** | 43.205.25.29 |
| **Elastic IP** | 35.154.216.140 |
| **Jenkins URL** | http://35.154.216.140:8080 |
| **Region** | ap-south-1 (Mumbai) |
| **Instance Type** | t3.micro (Free Tier) |
| **Security Group** | sg-0df27d8d0c0c3cfb8 (Allows SSH 22, HTTP 8080, JNLP 50000) |

---

## ✅ What's Been Completed

1. ✅ Created Jenkins EC2 Terraform module with full IAM/security configuration
2. ✅ Fixed Java installation issue (switched from amazon-linux-extras to Amazon Corretto)
3. ✅ Provisioned Jenkins EC2 instance successfully
4. ✅ Assigned Elastic IP for stable webhook endpoint
5. ✅ Created 3 Jenkinsfiles (dev/staging/prod) with full CI/CD pipelines
6. ✅ Created helper scripts for password retrieval and status checking

---

## ⏳ Current Status: Jenkins Initializing

Jenkins typically takes **2-4 minutes** to fully initialize after EC2 instance creation. The instance was created at approximately **08:14 UTC**.

### Check if Jenkins is Ready

Run this command periodically to check status:

```powershell
Invoke-WebRequest -Uri "http://35.154.216.140:8080" -Method Head -TimeoutSec 5
```

**Expected responses:**
- `StatusCode: 200` or `StatusCode: 403` = Jenkins is READY ✅
- `Timeout` or `Connection refused` = Still initializing, wait 1-2 more minutes ⏳

---

##  How to Get the Initial Admin Password

### Option 1: AWS Console (Recommended - No SSH Required)

1. **Open AWS EC2 Console**:  
   https://ap-south-1.console.aws.amazon.com/ec2/v2/home?region=ap-south-1#Instances:

2. **Select instance**: `i-09440e039f8557c49`

3. **Get System Log**:  
   Actions → Monitor and troubleshoot → Get system log

4. **Search** for: `Jenkins initial setup is required`  
   (Ctrl+F or Cmd+F)

5. **Copy the 32-character password** that appears below that line

### Option 2: PowerShell Script (Automated)

Once Jenkins is ready (after 3-4 minutes), run:

```powershell
cd "c:\Users\rishi\OneDrive\Documents\dhee-devops-project\DevOps-Assignment"
.\get-password.ps1
```

This will automatically retrieve and copy the password to your clipboard.

### Option 3: AWS CLI

```powershell
aws ec2 get-console-output --instance-id i-09440e039f8557c49 --region ap-south-1 --output text | Select-String -Pattern "([a-f0-9]{32})"
```

### Option 4: SSH (If You Have a Key Pair)

```bash
ssh -i your-key.pem ec2-user@35.154.216.140
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🚀 Once Jenkins is Accessible

1. **Open Jenkins**: http://35.154.216.140:8080

2. **Enter initial admin password** (from above)

3. **Install suggested plugins**:
   - Click "Install suggested plugins"
   - Wait 5-10 minutes for installation

4. **Create admin user**:
   - Username: `admin`
   - Password: Create a secure password
   - Full name: `Jenkins Admin`
   - Email: your-email@example.com

5. **Confirm Jenkins URL**: Keep default

6. **Click "Start using Jenkins"**

---

## 🔧 Post-Setup: Install Additional Plugins

Navigate to **Manage Jenkins** → **Plugins** → **Available**

Required plugins:
- ✅ **Docker** - For container builds
- ✅ **Docker Pipeline** - Pipeline Docker integration
- ✅ **Git** - Source control (usually pre-installed)
- ✅ **GitHub** - GitHub integration
- ✅ **SonarQube Scanner** - Code quality analysis
- ✅ **AWS SDK** / **Pipeline: AWS Steps** - ECS deployment
- ⚠️ **Trivy** - Container vulnerability scanning (install manually if not available)

After installing, **restart Jenkins**:  
Manage Jenkins → Restart Jenkins

---

## 🔐 Add Credentials

### GitHub Credentials

1. Manage Jenkins → Credentials → System → Global credentials
2. Add Credentials
3. Kind: **Username with password**
4. Username: `github-token` (or your GitHub username)
5. Password: Your GitHub Personal Access Token
6. ID: `github-credentials`
7. Description: `GitHub API Token`

### Docker Hub Credentials

1. Add Credentials
2. Kind: **Username with password**
3. Username: Your Docker Hub username
4. Password: Your Docker Hub access token
5. ID: `docker-hub-credentials`
6. Description: `Docker Hub Credentials`

---

## 📋 Create Pipeline Jobs

### Job 1: Dev Pipeline

1. **New Item** → Name: `dhee-devops-dev` → Type: **Pipeline**
2. **General**:
   - ☑ GitHub project: `https://github.com/YOURUSERNAME/YOURREPO`
3. **Build Triggers**:
   - ☑ GitHub hook trigger for GITScm polling
4. **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/YOURUSERNAME/YOURREPO.git`
   - Credentials: Select `github-credentials`
   - Branch: `*/dev`
   - Script Path: `Jenkinsfile-dev`

### Job 2: Staging Pipeline

Repeat above, but:
- Name: `dhee-devops-staging`
- Branch: `*/staging`
- Script Path: `Jenkinsfile-staging`

### Job 3: Production Pipeline

Repeat above, but:
- Name: `dhee-devops-prod`
- Branch: `*/main` or `*/prod`
- Script Path: `Jenkinsfile-prod`

---

## 🔗 Configure GitHub Webhook

1. Go to your GitHub repository
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://35.154.216.140:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**:  
   - ☑ Just the push event
   - Or select individual events (Push, Pull request)
6. **Active**: ☑
7. **Add webhook**

Verify: Check **Recent Deliveries** for green checkmark ✓

---

## 🐞 Troubleshooting

### Jenkins Not Accessible After 5+ Minutes

**Check instance status**:
```powershell
aws ec2 describe-instance-status --instance-ids i-09440e039f8557c49 --region ap-south-1
```

**Check security group**:
```powershell
aws ec2 describe-security-groups --group-ids sg-0df27d8d0c0c3cfb8 --region ap-south-1 --query 'SecurityGroups[0].IpPermissions[?FromPort==`8080`]'
```

**Get detailed console logs**:
```powershell
aws ec2 get-console-output --instance-id i-09440e039f8557c49 --region ap-south-1 --output text > console.log
notepad console.log
```

Look for errors related to:
- Java installation
- Jenkins installation
- Service startup failures

### If Jenkins Service Failed to Start

This requires SSH access. If you have a key pair:

```bash
ssh -i your-key.pem ec2-user@35.154.216.140

# Check Jenkins service status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -n 100

# Check if Java installed correctly
java -version

# Manually start Jenkins if needed
sudo systemctl start jenkins
```

---

## 📁 Created Files Reference

| File | Purpose |
|------|---------|
| [Jenkinsfile-dev](Jenkinsfile-dev) | Dev environment CI/CD pipeline |
| [Jenkinsfile-staging](Jenkinsfile-staging) | Staging environment pipeline with tests |
| [Jenkinsfile-prod](Jenkinsfile-prod) | Production pipeline with manual approval|
| [JENKINS_SETUP.md](JENKINS_SETUP.md) | Detailed setup guide |
| [JENKINS_ACCESS.md](JENKINS_ACCESS.md) | Access instructions |
| [get-password.ps1](get-password.ps1) | Password retrieval script |
| [check-jenkins.ps1](check-jenkins.ps1) | Status checker |
| [wait-for-jenkins.ps1](wait-for-jenkins.ps1) | Initialization monitor |

---

## 🎯 Pipeline Architecture

```
GitHub Repository (dev/staging/main branches)
    ↓ Webhook Trigger
Jenkins (http://35.154.216.140:8080)
    ├─ Git Checkout
    ├─ SonarQube Code Quality Scan
    ├─ Docker Build (Backend + Frontend)
    ├─ Trivy Vulnerability Scan
    ├─ Push to ECR + Docker Hub
    └─ Deploy to ECS (Dev/Staging auto, Prod manual approval)
```

---

## Next Session Checklist

- [ ] Open http://35.154.216.140:8080 in browser
- [ ] Enter initial admin password  
- [ ] Install suggested plugins
- [ ] Create admin user
- [ ] Install additional plugins (Docker, SonarQube, AWS)
- [ ] Add GitHub credentials  
- [ ] Add Docker Hub credentials
- [ ] Create 3 pipeline jobs (dev/staging/prod)
- [ ] Configure GitHub webhook
- [ ] Test manual pipeline run
- [ ] Push code to GitHub and watch auto-trigger

---

**Instance was created at**: ~08:14 UTC, February 27, 2026  
**Give it until**: ~08:18-08:20 UTC before troubleshooting  
**If still not working after 10 minutes**: Check console logs for errors

**All infrastructure is provisioned**. You just need to wait for Jenkins to finish initializing, then access the UI and complete the setup wizard!
