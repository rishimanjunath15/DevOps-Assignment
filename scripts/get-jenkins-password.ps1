# Script to retrieve Jenkins initial admin password
# Run this script to get the initial password for Jenkins setup

$INSTANCE_ID = "i-02c1d92a4dea36304"
$REGION = "ap-south-1"
$JENKINS_URL = "http://13.201.88.252:8080"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Jenkins Initial Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check instance status
Write-Host "[1/4] Checking Jenkins EC2 instance status..." -ForegroundColor Yellow
try {
    $instanceState = aws ec2 describe-instances `
        --instance-ids $INSTANCE_ID `
        --region $REGION `
        --query 'Reservations[0].Instances[0].State.Name' `
        --output text 2>&1
    
    if ($instanceState -eq "running") {
        Write-Host "✓ Instance is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Instance state: $instanceState" -ForegroundColor Red
        Write-Host "Please wait for the instance to be in 'running' state" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Failed to check instance status" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""

# Check if Jenkins is accessible
Write-Host "[2/4] Checking if Jenkins is accessible..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $JENKINS_URL -Method Head -TimeoutSec 10 -ErrorAction SilentlyContinue
    Write-Host "✓ Jenkins is accessible at $JENKINS_URL" -ForegroundColor Green
} catch {
    Write-Host "⚠ Jenkins may still be initializing (this can take 2-3 minutes)" -ForegroundColor Yellow
    Write-Host "  If this persists, check security group allows port 8080" -ForegroundColor Gray
}

Write-Host ""

# Get console output to find password
Write-Host "[3/4] Retrieving initial admin password from EC2 console logs..." -ForegroundColor Yellow
try {
    $consoleOutput = aws ec2 get-console-output `
        --instance-id $INSTANCE_ID `
        --region $REGION `
        --output text 2>&1
    
    if ($consoleOutput -match "([a-f0-9]{32})") {
        $password = $matches[1]
        Write-Host "✓ Password found!" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "JENKINS INITIAL ADMIN PASSWORD" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host $password -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Copy to clipboard
        $password | Set-Clipboard
        Write-Host "✓ Password copied to clipboard!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Password not found in console logs yet" -ForegroundColor Yellow
        Write-Host "  Jenkins may still be initializing..." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Alternative: Use AWS Systems Manager to connect:" -ForegroundColor Cyan
        Write-Host "  aws ssm start-session --target $INSTANCE_ID --region $REGION" -ForegroundColor Gray
        Write-Host "  Then run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to retrieve console output" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""

# Open browser
Write-Host "[4/4] Opening Jenkins in browser..." -ForegroundColor Yellow
Write-Host "Jenkins URL: $JENKINS_URL" -ForegroundColor Cyan
Write-Host ""

try {
    Start-Process $JENKINS_URL
    Write-Host "✓ Browser opened!" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not open browser automatically" -ForegroundColor Yellow
    Write-Host "  Please open manually: $JENKINS_URL" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Paste the password above into Jenkins UI" -ForegroundColor White
Write-Host "2. Click Install suggested plugins" -ForegroundColor White
Write-Host "3. Create admin user" -ForegroundColor White
Write-Host "4. Follow JENKINS_SETUP.md for detailed instructions" -ForegroundColor White
Write-Host ""
