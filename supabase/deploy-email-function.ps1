# Supabase Edge Function Deployment Script
# Replace the values below with your actual SMTP credentials

# For Gmail (Development):
supabase secrets set SMTP_HOSTNAME=smtp.gmail.com
supabase secrets set SMTP_PORT=587
supabase secrets set SMTP_USERNAME=your-email@gmail.com
supabase secrets set SMTP_PASSWORD=your-16-char-app-password
supabase secrets set SMTP_FROM_EMAIL=your-email@gmail.com

# For SendGrid (Production):
# supabase secrets set SMTP_HOSTNAME=smtp.sendgrid.net
# supabase secrets set SMTP_PORT=587
# supabase secrets set SMTP_USERNAME=apikey
# supabase secrets set SMTP_PASSWORD=your-sendgrid-api-key
# supabase secrets set SMTP_FROM_EMAIL=noreply@yourdomain.com

# After setting secrets, deploy the function:
# supabase functions deploy send-email

# Test the function locally:
# supabase functions serve send-email

# View logs:
# supabase functions logs send-email
