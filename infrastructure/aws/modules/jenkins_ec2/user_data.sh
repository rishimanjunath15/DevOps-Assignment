#!/bin/bash
set +e
# Log to file, syslog AND /dev/console so output is visible in EC2 Console Output
exec > >(tee /var/log/jenkins-userdata.log | tee /dev/console | logger -t jenkins-setup) 2>&1

echo "===== Jenkins EC2 Setup Started: $(date) ====="

# ─── 1. System update ────────────────────────────────────────────────────────
echo "[1/6] Updating system..."
yum update -y
yum install -y wget curl git unzip

# ─── 2. Install Java 17 (required by Jenkins LTS 2.387.3+) ──────────────────
echo "[2/6] Installing Java 17 (Amazon Corretto)..."
yum install -y java-17-amazon-corretto
if java -version 2>&1; then
    echo "Java 17 OK"
else
    echo "Corretto 17 failed, trying OpenJDK 17..."
    yum install -y java-17-openjdk
    java -version
fi

JAVA_BIN=$(readlink -f $(which java) 2>/dev/null || echo "")
if [ -n "$JAVA_BIN" ]; then
    JAVA_HOME_VAL=$(dirname $(dirname "$JAVA_BIN"))
    echo "export JAVA_HOME=$JAVA_HOME_VAL" >> /etc/profile.d/java.sh
    echo "export PATH=\$PATH:\$JAVA_HOME/bin"  >> /etc/profile.d/java.sh
    export JAVA_HOME="$JAVA_HOME_VAL"
fi
echo "JAVA_HOME=$JAVA_HOME"
java -version

# ─── 3. Install Docker ───────────────────────────────────────────────────────
echo "[3/6] Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
docker --version && echo "Docker OK"

# ─── 4. Install Jenkins ──────────────────────────────────────────────────────
echo "[4/6] Installing Jenkins..."

# Add Jenkins stable repo
wget -q -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import 2023 GPG key (pkg.jenkins.io rotated keys in March 2023)
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins (use --nogpgcheck as fallback insurance)
yum install -y jenkins --nogpgcheck

# Ensure Jenkins home directory exists
JENKINS_HOME="/var/lib/jenkins"
mkdir -p "$JENKINS_HOME"
chown -R jenkins:jenkins "$JENKINS_HOME"
chmod 755 "$JENKINS_HOME"

# Add jenkins to docker group
usermod -aG docker jenkins

# Start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Wait up to 2 minutes for Jenkins to start
echo "Waiting for Jenkins to start..."
for i in $(seq 1 12); do
    sleep 10
    if systemctl is-active --quiet jenkins; then
        echo "Jenkins is running! (attempt $i)"
        break
    fi
    echo "Attempt $i/12: Jenkins not yet active..."
    if [ "$i" -eq 12 ]; then
        echo "ERROR: Jenkins did not start. Dumping journal:"
        journalctl -u jenkins -n 60 --no-pager
    fi
done

echo "Jenkins service status:"
systemctl status jenkins --no-pager

echo "========================================================="
echo "Jenkins initial admin password:"
if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
    cat "$JENKINS_HOME/secrets/initialAdminPassword"
else
    echo "Password file not yet available (Jenkins may still be initialising)"
fi
echo "========================================================="

# ─── 5. Install AWS CLI v2 ───────────────────────────────────────────────────
echo "[5/6] Installing AWS CLI v2..."
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install --update
rm -rf aws awscliv2.zip
aws --version && echo "AWS CLI OK"
cd /

# ─── 6. Install Docker Compose ───────────────────────────────────────────────
echo "[6/6] Installing Docker Compose..."
curl -sL \
    "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version && echo "Docker Compose OK"

echo ""
echo "===== Jenkins EC2 Setup Completed: $(date) ====="
PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 || echo "UNKNOWN")
echo "Jenkins URL: http://$${PUBLIC_IP}:8080"
echo "Setup log:   /var/log/jenkins-userdata.log"
