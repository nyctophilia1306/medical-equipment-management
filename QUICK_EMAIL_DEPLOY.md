# Quick Email Function Deployment Guide

Since Supabase CLI installation is complex on Windows, you can deploy the edge function directly through the Supabase Dashboard.

## Option 1: Deploy via Supabase Dashboard (Recommended)

1. **Go to your Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Edge Functions**
   - Click "Functions" in the left sidebar
   - Click "Create a new function"

3. **Create the Function**
   - Name: `send-email`
   - Click "Create function"

4. **Copy the Code**
   - Open: `supabase/functions/send-email/index.ts` (in this project)
   - Copy ALL the code
   - Paste it into the function editor in the dashboard
   - Click "Deploy"

5. **Set Environment Variables**
   - In the function settings, add these secrets:
     - `SMTP_HOSTNAME` = `smtp.gmail.com`
     - `SMTP_PORT` = `587`
     - `SMTP_USERNAME` = `your-email@gmail.com`
     - `SMTP_PASSWORD` = `your-gmail-app-password`
     - `SMTP_FROM_EMAIL` = `your-email@gmail.com`

## Option 2: Install Supabase CLI with Scoop (Alternative)

```powershell
# Install Scoop if you don't have it
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Install Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Then follow the original deployment steps
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set SMTP_HOSTNAME=smtp.gmail.com
supabase secrets set SMTP_PORT=587
supabase secrets set SMTP_USERNAME=your-email@gmail.com
supabase secrets set SMTP_PASSWORD=your-app-password
supabase secrets set SMTP_FROM_EMAIL=your-email@gmail.com
supabase functions deploy send-email
```

## Option 3: Use Without Edge Function (Temporary Testing)

For now, you can test email functionality by:

1. **Skip edge function deployment**
2. **Use Supabase built-in SMTP** for auth emails (sign up, password reset)
   - Go to Dashboard → Settings → Auth → SMTP Settings
   - Enter your Gmail SMTP settings there

3. **For custom notifications** (new requests, approvals, etc.):
   - These require the edge function
   - Can be added later when you deploy the function

## Getting Gmail App Password

1. Visit: https://myaccount.google.com/apppasswords
2. You need 2-Factor Authentication enabled first
3. Create new app password:
   - App: "Mail"
   - Device: "Other" → "Medical Equipment System"
4. Copy the 16-character password (format: xxxx xxxx xxxx xxxx)
5. Use this password in SMTP_PASSWORD

## Testing the Function (After Deployment)

```powershell
# Test with curl (PowerShell)
$headers = @{
    "Authorization" = "Bearer YOUR_ANON_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    type = "welcome"
    to = "test@example.com"
    data = @{
        user_name = "Test User"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-email" -Method POST -Headers $headers -Body $body
```

## Next Steps After Function is Deployed

1. Test the function with a welcome email
2. Set up database triggers (see SUPABASE_EMAIL_SETUP.md)
3. Integrate with your Flutter app
4. Monitor function logs in dashboard

## Recommendation

**For Development**: Use Option 1 (Dashboard deployment) - it's the fastest and easiest.

**For Production**: Install Supabase CLI properly with Scoop (Option 2) for better version control and CI/CD integration.
