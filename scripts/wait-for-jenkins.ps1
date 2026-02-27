Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " JENKINS INITIALIZATION MONITOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$jenkinsUrl = "http://65.0.244.133:8080"
$instanceId = "i-02c1d92a4dea36304"
$maxAttempts = 20
$attempt = 0

Write-Host "Jenkins was just created. Waiting for initialization..." -ForegroundColor Yellow
Write-Host "URL: $jenkinsUrl" -ForegroundColor Cyan
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray
Write-Host ""

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "[$attempt/$maxAttempts] Checking Jenkins..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $jenkinsUrl -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host " SUCCESS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host " JENKINS IS READY!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Opening Jenkins in your browser..." -ForegroundColor Cyan
        Start-Process $jenkinsUrl
        Write-Host ""
        Write-Host "Next: Run .\get-password.ps1 to get the initial admin password" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    } catch {
        if ($_.Exception.Message -match "403") {
            Write-Host " READY (403 is normal)!" -ForegroundColor Green
            Write-Host ""
            Write-Host "=========================================" -ForegroundColor Green
            Write-Host " JENKINS IS READY!" -ForegroundColor Green
            Write-Host "=========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Opening Jenkins in your browser..." -ForegroundColor Cyan
            Start-Process $jenkinsUrl
            Write-Host ""
            Write-Host "Next: Run .\get-password.ps1 to get the initial admin password" -ForegroundColor Yellow
            Write-Host ""
            exit 0
        } else {
            Write-Host " Not ready yet" -ForegroundColor Gray
        }
    }
    
    if ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 10
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Yellow
Write-Host "Jenkins is taking longer than expected" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please check:" -ForegroundColor White
Write-Host "1. Security group allows port 8080" -ForegroundColor Gray
Write-Host "2. User data script completed successfully" -ForegroundColor Gray
Write-Host ""
Write-Host "Check EC2 console logs:" -ForegroundColor Cyan
Write-Host "  aws ec2 get-console-output --instance-id $instanceId --region ap-south-1 --latest --output text" -ForegroundColor Gray
Write-Host ""
