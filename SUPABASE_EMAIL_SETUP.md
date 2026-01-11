# Supabase Email Notification Setup Guide

This guide explains how to set up email notifications for the Medical Equipment Management System using Supabase Edge Functions.

## Prerequisites

- Supabase project with admin access
- SMTP credentials (Gmail, SendGrid, or other email service)
- Supabase CLI installed (for deploying edge functions)

## Step 1: Configure Email Authentication in Supabase

1. Go to your Supabase Dashboard → Authentication → Email Templates
2. Enable email confirmations for new sign-ups
3. Customize email templates for:
   - Confirm signup
   - Reset password
   - Change email address

## Step 2: Set Up SMTP Settings

### Option A: Using SendGrid (Recommended for production)

1. Sign up for SendGrid account (free tier available)
2. Create an API key
3. In Supabase Dashboard → Settings → Auth → SMTP Settings:
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: <your-sendgrid-api-key>
   Sender email: noreply@yourdomain.com
   Sender name: Medical Equipment System
   ```

### Option B: Using Gmail (For development)

1. Enable 2-factor authentication on your Gmail account
2. Generate an App Password (https://myaccount.google.com/apppasswords)
3. In Supabase Dashboard → Settings → Auth → SMTP Settings:
   ```
   Host: smtp.gmail.com
   Port: 587
   Username: your-email@gmail.com
   Password: <your-app-password>
   Sender email: your-email@gmail.com
   Sender name: Medical Equipment System
   ```

## Step 3: Create Supabase Edge Function for Email Sending

### Install Supabase CLI

```powershell
# Install via npm
npm install -g supabase

# Or via Scoop (Windows)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Initialize Supabase Project

```powershell
cd C:\Users\PC\Documents\DATN\medical\flutter_application_1
supabase init
supabase login
supabase link --project-ref <your-project-ref>
```

### Create Edge Function

```powershell
supabase functions new send-email
```

### Edge Function Code (supabase/functions/send-email/index.ts)

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  type: string
  to: string
  data: Record<string, any>
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { type, to, data }: EmailRequest = await req.json()

    const client = new SMTPClient({
      connection: {
        hostname: Deno.env.get("SMTP_HOSTNAME")!,
        port: Number(Deno.env.get("SMTP_PORT")),
        tls: true,
        auth: {
          username: Deno.env.get("SMTP_USERNAME")!,
          password: Deno.env.get("SMTP_PASSWORD")!,
        },
      },
    })

    let subject = ""
    let html = ""

    switch (type) {
      case "new_request":
        subject = `Yêu cầu mượn thiết bị mới từ ${data.user_name}`
        html = `
          <h2>Yêu cầu mượn thiết bị mới</h2>
          <p><strong>Người mượn:</strong> ${data.user_name}</p>
          <p><strong>Thiết bị:</strong> ${data.equipment_name}</p>
          <p><strong>Mã yêu cầu:</strong> ${data.request_id}</p>
          <p>Vui lòng đăng nhập vào hệ thống để xem chi tiết và duyệt yêu cầu.</p>
        `
        break

      case "request_approved":
        subject = `Yêu cầu mượn thiết bị được duyệt`
        html = `
          <h2>Yêu cầu của bạn đã được duyệt</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Yêu cầu mượn thiết bị <strong>${data.equipment_name}</strong> của bạn đã được chấp thuận.</p>
          <p><strong>Ngày mượn:</strong> ${new Date(data.borrow_date).toLocaleDateString('vi-VN')}</p>
          <p><strong>Ngày trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p>Vui lòng đến nhận thiết bị theo đúng thời gian.</p>
        `
        break

      case "request_rejected":
        subject = `Yêu cầu mượn thiết bị bị từ chối`
        html = `
          <h2>Yêu cầu của bạn bị từ chối</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Yêu cầu mượn thiết bị <strong>${data.equipment_name}</strong> của bạn đã bị từ chối.</p>
          <p><strong>Lý do:</strong> ${data.reason}</p>
          <p>Vui lòng liên hệ với quản trị viên để biết thêm chi tiết.</p>
        `
        break

      case "equipment_overdue":
        subject = `Thiết bị quá hạn trả - Vui lòng trả ngay`
        html = `
          <h2>Thiết bị đã quá hạn trả</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Thiết bị <strong>${data.equipment_name}</strong> của bạn đã quá hạn trả ${data.days_overdue} ngày.</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p style="color: red;"><strong>Vui lòng trả thiết bị ngay lập tức để tránh bị xử lý kỷ luật.</strong></p>
        `
        break

      case "equipment_overdue_admin":
        subject = `Thiết bị quá hạn - ${data.user_name}`
        html = `
          <h2>Cảnh báo thiết bị quá hạn</h2>
          <p><strong>Người mượn:</strong> ${data.user_name}</p>
          <p><strong>Thiết bị:</strong> ${data.equipment_name}</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p><strong>Số ngày quá hạn:</strong> ${data.days_overdue} ngày</p>
          <p>Vui lòng liên hệ với người mượn để thu hồi thiết bị.</p>
        `
        break

      case "return_reminder":
        subject = `Nhắc nhở: Sắp đến hạn trả thiết bị`
        html = `
          <h2>Nhắc nhở trả thiết bị</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Thiết bị <strong>${data.equipment_name}</strong> của bạn sắp đến hạn trả.</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p>Vui lòng chuẩn bị trả thiết bị đúng hạn.</p>
        `
        break

      case "welcome":
        subject = `Chào mừng đến với Hệ thống Quản lý Thiết bị Y tế`
        html = `
          <h2>Chào mừng ${data.user_name}!</h2>
          <p>Cảm ơn bạn đã đăng ký tài khoản tại Hệ thống Quản lý Thiết bị Y tế.</p>
          <p>Bạn có thể đăng nhập và bắt đầu sử dụng hệ thống ngay bây giờ.</p>
          <p>Nếu bạn có bất kỳ thắc mắc nào, vui lòng liên hệ với quản trị viên.</p>
        `
        break

      case "password_reset":
        subject = `Mật khẩu của bạn đã được đặt lại`
        html = `
          <h2>Mật khẩu đã được đặt lại</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Mật khẩu của bạn đã được đặt lại thành công.</p>
          <p>Vui lòng đăng nhập và đổi mật khẩu mới để bảo mật tài khoản.</p>
        `
        break

      default:
        throw new Error(`Unknown email type: ${type}`)
    }

    await client.send({
      from: Deno.env.get("SMTP_FROM_EMAIL")!,
      to: to,
      subject: subject,
      html: html,
    })

    await client.close()

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### Deploy Edge Function

```powershell
# Set environment variables
supabase secrets set SMTP_HOSTNAME=smtp.gmail.com
supabase secrets set SMTP_PORT=587
supabase secrets set SMTP_USERNAME=your-email@gmail.com
supabase secrets set SMTP_PASSWORD=your-app-password
supabase secrets set SMTP_FROM_EMAIL=your-email@gmail.com

# Deploy the function
supabase functions deploy send-email
```

## Step 4: Create Database Triggers for Automatic Notifications

Execute these SQL queries in your Supabase SQL Editor:

### Trigger for New Borrow Requests

```sql
-- Function to notify admins of new requests
CREATE OR REPLACE FUNCTION notify_new_request()
RETURNS TRIGGER AS $$
DECLARE
  admin_email TEXT;
  user_name TEXT;
  equipment_name TEXT;
BEGIN
  -- Get user name
  SELECT full_name INTO user_name
  FROM users
  WHERE user_id = NEW.user_id;

  -- Get equipment name
  SELECT name INTO equipment_name
  FROM equipment
  WHERE equipment_id = NEW.equipment_id;

  -- Get all admin emails with notifications enabled
  FOR admin_email IN
    SELECT u.email
    FROM users u
    INNER JOIN user_settings us ON u.user_id = us.user_id
    WHERE u.role_id = 0 AND us.email_notifications = true AND u.email IS NOT NULL
  LOOP
    -- Call edge function to send email
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', 'new_request',
        'to', admin_email,
        'data', jsonb_build_object(
          'user_name', user_name,
          'equipment_name', equipment_name,
          'request_id', NEW.request_id
        )
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_new_borrow_request ON borrow_request;
CREATE TRIGGER on_new_borrow_request
  AFTER INSERT ON borrow_request
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION notify_new_request();
```

### Trigger for Request Status Changes

```sql
-- Function to notify users of status changes
CREATE OR REPLACE FUNCTION notify_status_change()
RETURNS TRIGGER AS $$
DECLARE
  user_email TEXT;
  user_name TEXT;
  equipment_name TEXT;
  notification_enabled BOOLEAN;
BEGIN
  -- Only proceed if status changed
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  -- Get user email and check if notifications are enabled
  SELECT u.email, u.full_name, us.email_notifications
  INTO user_email, user_name, notification_enabled
  FROM users u
  LEFT JOIN user_settings us ON u.user_id = us.user_id
  WHERE u.user_id = NEW.user_id;

  -- Skip if no email or notifications disabled
  IF user_email IS NULL OR NOT notification_enabled THEN
    RETURN NEW;
  END IF;

  -- Get equipment name
  SELECT name INTO equipment_name
  FROM equipment
  WHERE equipment_id = NEW.equipment_id;

  -- Send notification based on new status
  IF NEW.status = 'approved' THEN
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', 'request_approved',
        'to', user_email,
        'data', jsonb_build_object(
          'user_name', user_name,
          'equipment_name', equipment_name,
          'borrow_date', NEW.borrow_date,
          'return_date', NEW.return_date
        )
      )
    );
  ELSIF NEW.status = 'rejected' THEN
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', 'request_rejected',
        'to', user_email,
        'data', jsonb_build_object(
          'user_name', user_name,
          'equipment_name', equipment_name,
          'reason', NEW.notes
        )
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_request_status_change ON borrow_request;
CREATE TRIGGER on_request_status_change
  AFTER UPDATE ON borrow_request
  FOR EACH ROW
  EXECUTE FUNCTION notify_status_change();
```

### Scheduled Function for Overdue Checks (pg_cron)

```sql
-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily check for overdue equipment (runs at 9 AM every day)
SELECT cron.schedule(
  'check-overdue-equipment',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/check-overdue',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);

-- Schedule return reminders (runs at 8 AM every day)
SELECT cron.schedule(
  'send-return-reminders',
  '0 8 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
```

## Step 5: Update Flutter App Configuration

The `EmailNotificationService` class is already created in your Flutter app at:
`lib/services/email_notification_service.dart`

### Usage Example in BorrowService

Add these lines after creating/updating borrow requests:

```dart
// After creating a new request
if (result != null) {
  final emailService = EmailNotificationService();
  final adminEmails = await emailService.getAdminEmailsForNotifications();
  
  for (final adminEmail in adminEmails) {
    await emailService.sendNewRequestNotification(
      adminEmail: adminEmail,
      userName: userName,
      equipmentName: equipmentName,
      requestId: result,
    );
  }
}

// After approving a request
final emailService = EmailNotificationService();
final notificationsEnabled = await emailService.isEmailNotificationEnabled(userId);

if (notificationsEnabled && userEmail != null) {
  await emailService.sendApprovedNotification(
    userEmail: userEmail,
    userName: userName,
    equipmentName: equipmentName,
    borrowDate: borrowDate,
    returnDate: returnDate,
  );
}
```

## Step 6: Testing

1. Test individual email notifications using Supabase Functions:
   ```bash
   supabase functions serve send-email
   ```

2. Test with curl:
   ```bash
   curl -i --location --request POST 'http://localhost:54321/functions/v1/send-email' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"type":"welcome","to":"test@example.com","data":{"user_name":"Test User"}}'
   ```

3. Monitor function logs:
   ```bash
   supabase functions logs send-email
   ```

## Troubleshooting

### Common Issues

1. **Emails not sending:**
   - Verify SMTP credentials
   - Check edge function logs: `supabase functions logs send-email`
   - Ensure service role key is set correctly

2. **Triggers not firing:**
   - Check trigger status: `SELECT * FROM pg_trigger;`
   - Verify user has email in database
   - Check user_settings.email_notifications is true

3. **Rate limiting:**
   - Gmail: 500 emails/day (free)
   - SendGrid: 100 emails/day (free tier)
   - Consider upgrading for production use

## Production Recommendations

1. **Use SendGrid or AWS SES** for reliable email delivery
2. **Implement email queue** to handle rate limits
3. **Add email templates** with proper branding
4. **Monitor bounce rates** and invalid emails
5. **Implement unsubscribe functionality** for compliance
6. **Add email logs** in database for auditing

## Security Notes

- Never commit SMTP credentials to git
- Use Supabase secrets for all sensitive data
- Implement rate limiting to prevent abuse
- Validate all email addresses before sending
- Use service role key only in edge functions, never in Flutter app
