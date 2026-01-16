# Row Level Security (RLS) Policies Migration

## Problem
You're getting the error:
```
Exception: Database error creating user: PostgrestException(message: new row violates row-level security policy for table "users", code: 42501)
```

This happens because Supabase has Row Level Security enabled on the `users` table, but there are no policies configured to allow inserting new users.

## Solution
Apply the migration file `002_add_users_rls_policies.sql` which adds the necessary RLS policies.

## How to Apply

### Option 1: Supabase Dashboard (Recommended)

1. Open your Supabase project dashboard
2. Go to **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. Copy the entire contents of `002_add_users_rls_policies.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)
7. You should see "Success. No rows returned"

### Option 2: Supabase CLI

If you have the Supabase CLI installed:

```bash
cd c:\Users\PC\Documents\DATN\medical\flutter_application_1
supabase db push
```

## What This Migration Does

### 1. Enables RLS
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

### 2. Adds Service Role Policy
Allows your Flutter app (using service role key) to perform all operations:
- **Policy**: "Service role has full access to users"

### 3. Adds User Policies
- **Read own profile**: Users can view their own data
- **Update own profile**: Users can update their own data

### 4. Adds Admin Policies (role_id = 0)
- **View all users**: Admins can read all user records
- **Insert users**: Admins can create new users
- **Update any user**: Admins can modify any user
- **Delete users**: Admins can delete users

### 5. Adds Manager Policies (role_id = 1)
- **View all users**: Managers can read all user records

### 6. Adds Authenticated User Creation Policy
Allows authenticated users to create new user records (needed for the borrow service)

### 7. Helper Functions
- `is_admin()`: Check if current user is admin
- `is_admin_or_manager()`: Check if current user is admin or manager

## Verification

After applying the migration, run these queries in Supabase SQL Editor:

### 1. Check if RLS is enabled:
```sql
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'users';
```
Expected: `relrowsecurity = true`

### 2. List all policies on users table:
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'users';
```
Expected: Should show all 9 policies created

### 3. Test user creation:
Try creating a user from your Flutter app again. The error should be resolved.

## Troubleshooting

### Still getting RLS error?

1. **Check your Supabase client initialization**:
   Make sure you're using the correct API keys in your Flutter app.

2. **For borrow service user creation**:
   The borrow service creates users without authentication. If you need this:
   - Uncomment the "Allow anon inserts for borrow users" policy in the migration
   - Run it again in SQL Editor

3. **Check if policies are applied**:
   ```sql
   SELECT COUNT(*) as policy_count 
   FROM pg_policies 
   WHERE tablename = 'users';
   ```
   Should return at least 8-9 policies.

4. **Check your app's authentication state**:
   Make sure the user performing the action is properly authenticated.

## Security Notes

- **Service role policies**: These use `service_role` which has unrestricted access. Only use the service role key on the backend/server side, never expose it in client code.
  
- **Admin checks**: Policies check if `role_id = 0` to grant admin privileges. Make sure your first admin user is created correctly.

- **Authenticated policy**: The "Allow authenticated inserts for user creation" policy allows ANY authenticated user to create users. If you want more restriction, modify this policy.

## Rollback

If you need to remove these policies:

```sql
-- Drop all policies
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can insert users" ON users;
DROP POLICY IF EXISTS "Admins can update any user" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;
DROP POLICY IF EXISTS "Managers can view all users" ON users;
DROP POLICY IF EXISTS "Allow authenticated inserts for user creation" ON users;

-- Drop helper functions
DROP FUNCTION IF EXISTS is_admin();
DROP FUNCTION IF EXISTS is_admin_or_manager();

-- Optionally disable RLS (not recommended)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
```

## Next Steps

After applying this migration:
1. Test user creation from your Flutter app
2. Verify that different user roles have appropriate access
3. Check that regular users can only see/edit their own profiles
4. Verify admins can manage all users

## Need Help?

If issues persist:
1. Check Supabase logs in the Dashboard → Logs
2. Verify your Flutter app is using the correct Supabase URL and keys
3. Make sure you have at least one admin user (role_id = 0) in your database
4. Check the Flutter console for detailed error messages
