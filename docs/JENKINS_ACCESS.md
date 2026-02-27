# Jenkins Access Guide

## 🚀 Quick Access

**Jenkins URL**: http://13.201.88.252:8080  
**Status**: Instance is running, Jenkins initializing (takes 2-3 minutes)

---

## Method 1: Get Password from EC2 Console (Easiest - No SSH needed)

Run this command to retrieve the password:

```powershell
.\get-password.ps1
```

If password not found yet, **wait 2-3 minutes** and run again.

---

## Method 2: Get Password via AWS Console (Web UI)

1. Go to **AWS EC2 Console**: https://ap-south-1.console.aws.amazon.com/ec2/v2/home?region=ap-south-1#Instances:instanceId=i-07247739adf11962b
2. Select instance `i-07247739adf11962b`
3. Click **Actions** → **Monitor and troubleshoot** → **Get system log**
4. Search (Ctrl+F) for: `Jenkins initial setup is required`
5. Copy the 32-character password that appears below that line

---

## Method 3: Get Password via SSH (Requires SSH Key)

If you have an SSH key configured for this instance:

```bash
ssh -i your-key.pem ec2-user@13.201.88.252
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Method 4: Wait and Check Browser

Sometimes Jenkins shows the password directly in the UI:

1. Open http://13.201.88.252:8080
2. If Jenkins is ready, you'll see "Unlock Jenkins" page
3. The page shows where the password file is located
4. Use Method 2 or 3 above to get it

---

## ⏱️ Troubleshooting: "Connection Refused" or "502 Bad Gateway"

Jenkins is still starting up! This is normal and takes 2-4 minutes after EC2 launch.

**Check Jenkins status** (every 30 seconds):
```powershell
Invoke-WebRequest -Uri http://13.201.88.252:8080 -Method Head
```

When you see `StatusCode : 200` or `StatusCode : 403`, Jenkins is ready!

---

## ✅ Once You Have the Password

1. **Open Jenkins**: http://13.201.88.252:8080
2. **Paste password** into "Administrator password" field
3. **Click Continue**
4. **Select "Install suggested plugins"**
5. **Wait 5-10 minutes** for plugins to install
6. **Create admin user**:
   - Username: `admin`
   - Password: *(create a secure password)*
   - Full name: `Jenkins Admin`
   - Email: `your-email@example.com`
7. **Confirm Jenkins URL**: Keep default
8. **Start using Jenkins**

---

## 🔧 Next Steps After Setup

Follow the detailed guide in **[JENKINS_SETUP.md](JENKINS_SETUP.md)** for:
- Installing additional plugins (Docker, SonarQube, AWS, Trivy)
- Adding GitHub and Docker Hub credentials
- Creating the 3 pipeline jobs (dev/staging/prod)
- Configuring GitHub webhooks
- Running your first build

---

## 📞 Still Having Issues?

### Jenkins won't start:
```powershell
# Check instance is running
aws ec2 describe-instances --instance-ids i-07247739adf11962b --region ap-south-1 --query 'Reservations[0].Instances[0].State.Name'

# Check security group allows port 8080
aws ec2 describe-security-groups --group-ids sg-0835e1e704f756f93 --region ap-south-1
```

### Can't connect to instance:
Your security group already allows:
- **Port 8080**: Jenkins UI (from anywhere)
- **Port 22**: SSH (from anywhere - restrict this in production!)

If still blocked, check your **local firewall** or **network restrictions**.

---

## 🎯 Current Status

- ✅ EC2 instance: **Running**
- ✅ Elastic IP: **13.201.88.252** (stable, won't change)
- ✅ Instance type: **t3.micro** (Free Tier eligible)
- ⏱️ Jenkins service: **Initializing** (allow 2-3 minutes)
- 📝 Setup scripts: **Created** (get-password.ps1)
- 📚 Documentation: **Complete** (JENKINS_SETUP.md)
- 🔧 Pipeline files: **Ready** (Jenkinsfile-dev/staging/prod)

---

**Created**: February 27, 2026  
**Jenkins Version**: Latest (will show after login)  
**Region**: ap-south-1 (Mumbai)
