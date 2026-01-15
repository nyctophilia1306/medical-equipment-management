# Database Migration: Update Email Column

## Overview
This migration updates the `users` table to make the `email` column required (NOT NULL) and adds necessary constraints.

## Changes Made

### 1. Database Schema Changes (SQL)
- Make `email` column NOT NULL
- Add UNIQUE constraint on email
- Add index on email for faster lookups
- Automatically populate missing emails with placeholder values

### 2. Model Changes (Dart)
- Changed `email` from `String?` (optional) to `String` (required) in User model
- Updated `fromJson` to provide empty string default for email
- Updated `toJson` to always include email field

## How to Apply the Migration

### Option 1: Via Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the migration file: `supabase/migrations/001_update_users_email_column.sql`
4. Copy the contents and paste into the SQL Editor
5. Click **Run** to execute the migration

### Option 2: Via Supabase CLI
If you have Supabase CLI installed:
```bash
supabase db push
```

### Option 3: Manual Execution
Connect to your database and run:
```sql
-- Update null emails
UPDATE users 
SET email = user_name || '@placeholder.local'
WHERE email IS NULL OR email = '';

-- Make email NOT NULL
ALTER TABLE users 
ALTER COLUMN email SET NOT NULL;

-- Add unique constraint
ALTER TABLE users 
ADD CONSTRAINT users_email_unique UNIQUE (email);

-- Add index
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

## Verification

After applying the migration, verify:

1. **Check column constraint:**
```sql
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'email';
```
Expected: `is_nullable = 'NO'`

2. **Check unique constraint:**
```sql
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'users' AND constraint_type = 'UNIQUE';
```
Expected: Should include `users_email_unique`

3. **Check all users have emails:**
```sql
SELECT COUNT(*) as users_without_email 
FROM users 
WHERE email IS NULL OR email = '';
```
Expected: `users_without_email = 0`

## Impact on Application

### Breaking Changes
- Any code that was creating users without emails will now fail
- The User model now requires email in constructors

### Non-Breaking Changes
- Existing code that already provides emails will continue to work
- The application should already be handling emails properly based on the codebase review

## Rollback

If you need to rollback this migration:
```sql
-- Remove constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_unique;
DROP INDEX IF EXISTS idx_users_email;

-- Make email nullable again
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
```

## Next Steps

1. Apply the database migration first
2. Then update your Flutter application (already done in the code)
3. Test user creation and authentication flows
4. Verify all users can login successfully

## Notes

- Users with placeholder emails (`@placeholder.local`) should update their emails
- Consider sending notifications to users with placeholder emails to update their information
- The migration is designed to be safe and non-destructive
