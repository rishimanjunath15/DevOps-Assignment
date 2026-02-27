Write-Host "==========================================="-ForegroundColor Cyan
Write-Host "  JENKINS STATUS CHECK" -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

$jenkinsUrl = "http://65.0.244.133:8080"
$instanceId = "i-02c1d92a4dea36304"

# Try to access Jenkins
Write-Host "[1] Checking Jenkins accessibility..." -ForegroundColor Yellow
try {
    $web = Invoke-WebRequest -Uri $jenkinsUrl -TimeoutSec 10 -UseBasicParsing
    Write-Host "SUCCESS! Jenkins is UP and running!" -ForegroundColor Green
    Write-Host "Status Code: $($web.StatusCode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Opening Jenkins in your browser..." -ForegroundColor Cyan
    Start-Process $jenkinsUrl
    Write-Host ""
    Write-Host "Next step: You need the initial admin password." -ForegroundColor Yellow
    Write-Host ""
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Write-Host "Jenkins is UP! (Got 403 - this is normal for initial setup)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Opening Jenkins in your browser..." -ForegroundColor Cyan
        Start-Process $jenkinsUrl
        Write-Host ""
    } else {
        Write-Host "Jenkins not accessible yet." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  - Jenkins is still starting (wait 1-2 more minutes)" -ForegroundColor White
        Write-Host "  - Security group issue" -ForegroundColor White
        Write-Host "  - Jenkins service failed to start" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host ""
Write-Host "[2] TO GET THE INITIAL PASSWORD:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option A - Via AWS Console (No SSH required):" -ForegroundColor Cyan
Write-Host "  1. Go to: https://ap-south-1.console.aws.amazon.com/ec2/v2/home?region=ap-south-1#Instances:" -ForegroundColor White
Write-Host "  2. Select instance: $instanceId" -ForegroundColor White
Write-Host "  3. Actions > Monitor and troubleshoot > Get system log" -ForegroundColor White
Write-Host "  4. Search for 'Jenkins initial setup'" -ForegroundColor White
Write-Host "  5. Copy the password" -ForegroundColor White
Write-Host ""

Write-Host "Option B - If you have SSH access:" -ForegroundColor Cyan
Write-Host "  ssh -i your-key.pem ec2-user@13.201.88.252" -ForegroundColor White
Write-Host "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword" -ForegroundColor White
Write-Host ""

Write-Host "Option C - Get from console output (command line):" -ForegroundColor Cyan  
Write-Host "  aws ec2 get-console-output --instance-id $instanceId --region ap-south-1 --output text | Select-String -Pattern `"([a-f0-9]{32})`"" -ForegroundColor White
Write-Host ""

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Jenkins URL: $jenkinsUrl" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "See JENKINS_ACCESS.md for detailed instructions" -ForegroundColor Gray
