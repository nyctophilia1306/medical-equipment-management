# Edge Function Test Script
# This script tests all email notification types in your Supabase edge function

Write-Host "=== Supabase Email Function Test ===" -ForegroundColor Cyan
Write-Host ""

# Configuration - Replace these values
$projectRef = Read-Host "Enter your Supabase Project Reference ID (from Dashboard URL)"
$anonKey = Read-Host "Enter your Supabase Anon Key (Dashboard > Settings > API)"
$testEmail = Read-Host "Enter your test email address"

Write-Host "`nStarting tests..." -ForegroundColor Yellow
Write-Host "Check your email: $testEmail" -ForegroundColor Yellow
Write-Host ""

$baseUrl = "https://$projectRef.supabase.co/functions/v1/send-mail"
$headers = @{
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

# Test counter
$testNumber = 1
$successCount = 0
$failCount = 0

function Test-EmailType {
    param (
        [string]$Type,
        [hashtable]$Data,
        [string]$Description
    )
    
    Write-Host "Test $testNumber : Testing '$Type' email..." -ForegroundColor White
    Write-Host "  Description: $Description" -ForegroundColor Gray
    
    $body = @{
        type = $Type
        to = $script:testEmail
        data = $Data
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $script:baseUrl -Method POST -Headers $script:headers -Body $body -ErrorAction Stop
        
        if ($response.success -eq $true) {
            Write-Host "  ✅ SUCCESS - Email sent!" -ForegroundColor Green
            $script:successCount++
        } else {
            Write-Host "  ❌ FAILED - Unexpected response" -ForegroundColor Red
            Write-Host "  Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
            $script:failCount++
        }
    }
    catch {
        Write-Host "  ❌ ERROR - $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            try {
                $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "  Error Details: $($errorObj.error)" -ForegroundColor Yellow
            } catch {
                Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
            }
        }
        $script:failCount++
    }
    
    Write-Host ""
    $script:testNumber++
    Start-Sleep -Seconds 2
}

# Test 1: Welcome Email
Test-EmailType -Type "welcome" -Data @{
    user_name = "Nguyen Van A"
} -Description "Welcome email for new user registration"

# Test 2: New Request Notification
Test-EmailType -Type "new_request" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    request_id = "REQ-2026-001"
} -Description "Admin notification for new borrow request"

# Test 3: Request Approved
Test-EmailType -Type "request_approved" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    borrow_date = (Get-Date).ToString("o")
    return_date = (Get-Date).AddDays(7).ToString("o")
} -Description "User notification for approved request"

# Test 4: Request Rejected
Test-EmailType -Type "request_rejected" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    reason = "Thiết bị đang được bảo trì"
} -Description "User notification for rejected request"

# Test 5: Equipment Overdue (User)
Test-EmailType -Type "equipment_overdue" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    return_date = (Get-Date).AddDays(-3).ToString("o")
    days_overdue = 3
} -Description "User notification for overdue equipment"

# Test 6: Equipment Overdue (Admin)
Test-EmailType -Type "equipment_overdue_admin" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    return_date = (Get-Date).AddDays(-3).ToString("o")
    days_overdue = 3
} -Description "Admin notification for overdue equipment"

# Test 7: Return Reminder
Test-EmailType -Type "return_reminder" -Data @{
    user_name = "Nguyen Van A"
    equipment_name = "Máy đo huyết áp điện tử"
    return_date = (Get-Date).AddDays(1).ToString("o")
} -Description "User reminder for upcoming return date"

# Test 8: Password Reset
Test-EmailType -Type "password_reset" -Data @{
    user_name = "Nguyen Van A"
} -Description "User notification for password reset"

# Summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor White
Write-Host "  Total Tests: $($testNumber - 1)" -ForegroundColor White
Write-Host "  Passed: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if ($successCount -eq ($testNumber - 1)) {
    Write-Host "🎉 All tests passed! Check your email inbox." -ForegroundColor Green
    Write-Host "You should have received $successCount emails at: $testEmail" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Check the errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor White
    Write-Host "  1. Check SMTP credentials in Supabase Dashboard" -ForegroundColor Gray
    Write-Host "  2. Verify all 5 secrets are set correctly" -ForegroundColor Gray
    Write-Host "  3. Check function logs in Dashboard > Functions > send-email > Logs" -ForegroundColor Gray
    Write-Host "  4. Ensure edge function is deployed successfully" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Check your email spam folder if emails are missing" -ForegroundColor Gray
Write-Host "  - View detailed logs: Dashboard > Edge Functions > send-email > Logs" -ForegroundColor Gray
Write-Host "  - If all passed, you're ready to integrate with Flutter app!" -ForegroundColor Gray
