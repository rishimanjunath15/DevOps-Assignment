# Jenkins Initial Password Retriever
$INSTANCE_ID = "i-02c1d92a4dea36304"
$REGION = "ap-south-1"
$JENKINS_URL = "http://65.0.244.133:8080"

Write-Host "========================================"
Write-Host "Retrieving Jenkins Initial Admin Password"
Write-Host "========================================"
Write-Host ""

# Method 1: Try to get from console logs
Write-Host "Checking EC2 console logs..."
$output = aws ec2 get-console-output --instance-id $INSTANCE_ID --region $REGION --output text 2>&1

if ($output -match "([a-f0-9]{32})") {
    $password = $matches[1]
    Write-Host ""
    Write-Host "SUCCESS! Initial Admin Password:" -ForegroundColor Green
    Write-Host "========================================"
    Write-Host $password -ForegroundColor Yellow
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Password has been copied to clipboard!" -ForegroundColor Green
    $password | Set-Clipboard
} else {
    Write-Host ""
    Write-Host "Password not yet available in logs." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please wait 2-3 minutes for Jenkins to initialize, then either:" -ForegroundColor Cyan
    Write-Host "  1. Run this script again" -ForegroundColor White
    Write-Host "  2. Use AWS Session Manager:" -ForegroundColor White
    Write-Host "     aws ssm start-session --target $INSTANCE_ID --region $REGION" -ForegroundColor Gray
    Write-Host "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Opening Jenkins in browser: $JENKINS_URL" -ForegroundColor Cyan
Start-Process $JENKINS_URL

Write-Host ""
Write-Host "Next: Follow JENKINS_SETUP.md for complete setup instructions" -ForegroundColor White
