# Test Supabase Auth SMTP Configuration
# This tests the built-in Supabase authentication email system

Write-Host "=== Testing Supabase Auth SMTP Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Get configuration
$projectRef = Read-Host "Enter your Supabase Project Reference ID"
$anonKey = Read-Host "Enter your Supabase Anon Key"
$testEmail = Read-Host "Enter your test email address"
$testPassword = "TestPassword123!"

Write-Host "`nAttempting to create test user and trigger email..." -ForegroundColor Yellow
Write-Host "This will test if your SMTP settings are working.`n" -ForegroundColor Gray

$baseUrl = "https://$projectRef.supabase.co/auth/v1"
$headers = @{
    "apikey" = $anonKey
    "Content-Type" = "application/json"
}

# Test 1: Sign up a new user (triggers confirmation email)
Write-Host "Test 1: Creating new user account (will send confirmation email)..." -ForegroundColor White

$signupBody = @{
    email = $testEmail
    password = $testPassword
    data = @{
        full_name = "Test User"
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/signup" -Method POST -Headers $headers -Body $signupBody -ErrorAction Stop
    
    Write-Host "  ✅ User created successfully!" -ForegroundColor Green
    Write-Host "  User ID: $($response.user.id)" -ForegroundColor Gray
    Write-Host "  Email: $($response.user.email)" -ForegroundColor Gray
    Write-Host "  Confirmation sent: $($response.user.confirmation_sent_at)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  📧 Check your email inbox for confirmation link!" -ForegroundColor Yellow
    Write-Host "  Also check spam folder if you don't see it." -ForegroundColor Gray
    Write-Host ""
    
    $userCreated = $true
}
catch {
    if ($_.Exception.Message -like "*User already registered*") {
        Write-Host "  ⚠️  User already exists. Testing password reset instead..." -ForegroundColor Yellow
        $userCreated = $false
    }
    else {
        Write-Host "  ❌ Failed to create user" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        if ($_.ErrorDetails.Message) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
        $userCreated = $false
    }
    Write-Host ""
}

# Test 2: Password reset (if user already exists)
if (-not $userCreated) {
    Write-Host "Test 2: Requesting password reset (will send reset email)..." -ForegroundColor White
    
    $resetBody = @{
        email = $testEmail
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/recover" -Method POST -Headers $headers -Body $resetBody -ErrorAction Stop
        
        Write-Host "  ✅ Password reset email sent!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  📧 Check your email inbox for password reset link!" -ForegroundColor Yellow
        Write-Host "  Also check spam folder if you don't see it." -ForegroundColor Gray
        Write-Host ""
    }
    catch {
        Write-Host "  ❌ Failed to send password reset" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        if ($_.ErrorDetails.Message) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# Summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Email Delivery Check:" -ForegroundColor White
Write-Host ""
Write-Host "If SMTP is configured correctly:" -ForegroundColor Yellow
Write-Host "  ✅ You should receive an email within 30 seconds" -ForegroundColor Green
Write-Host "  ✅ Check inbox and spam folder" -ForegroundColor Green
Write-Host "  ✅ Email sender: Your configured sender name" -ForegroundColor Green
Write-Host ""
Write-Host "If you DON'T receive an email:" -ForegroundColor Yellow
Write-Host "  1. Check Supabase Dashboard > Auth > Logs" -ForegroundColor Gray
Write-Host "  2. Verify SMTP settings: Dashboard > Settings > Auth > SMTP Settings" -ForegroundColor Gray
Write-Host "  3. Ensure Gmail App Password is correct (16 chars)" -ForegroundColor Gray
Write-Host "  4. Check that 2FA is enabled on your Gmail account" -ForegroundColor Gray
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Waiting 5 seconds for email to be sent..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Write-Host ""
Write-Host "Did you receive the email? (Check spam folder too)" -ForegroundColor Green
$received = Read-Host "Enter 'yes' if received, 'no' if not"

if ($received -eq "yes") {
    Write-Host ""
    Write-Host "🎉 SUCCESS! Your Supabase Auth SMTP is working correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "What's working now:" -ForegroundColor Cyan
    Write-Host "  ✅ User signup confirmation emails" -ForegroundColor Green
    Write-Host "  ✅ Password reset emails" -ForegroundColor Green
    Write-Host "  ✅ Email verification" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Flutter app authentication emails will work!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "❌ Email not received. Troubleshooting steps:" -ForegroundColor Red
    Write-Host ""
    Write-Host "1. Verify SMTP Configuration:" -ForegroundColor Yellow
    Write-Host "   Dashboard > Settings > Auth > SMTP Settings" -ForegroundColor Gray
    Write-Host "   Host: smtp.gmail.com" -ForegroundColor Gray
    Write-Host "   Port: 587" -ForegroundColor Gray
    Write-Host "   Username: your-gmail@gmail.com" -ForegroundColor Gray
    Write-Host "   Password: 16-char app password (not your Gmail password)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check Auth Logs:" -ForegroundColor Yellow
    Write-Host "   Dashboard > Auth > Logs" -ForegroundColor Gray
    Write-Host "   Look for SMTP errors or sending failures" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Gmail App Password:" -ForegroundColor Yellow
    Write-Host "   Make sure you created it correctly at:" -ForegroundColor Gray
    Write-Host "   https://myaccount.google.com/apppasswords" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Test in Supabase Dashboard:" -ForegroundColor Yellow
    Write-Host "   Dashboard > Auth > Users > Invite user" -ForegroundColor Gray
    Write-Host "   This sends a test email through your SMTP" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
