-- Migration: Add Row Level Security policies for users table
-- Simplified version without recursive policy checks

-- First, drop all existing policies if they exist
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Managers can view all users" ON users;
DROP POLICY IF EXISTS "Admins can insert users" ON users;
DROP POLICY IF EXISTS "Admins can update any user" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;
DROP POLICY IF EXISTS "Allow authenticated inserts for user creation" ON users;

-- Enable RLS on users table (if not already enabled)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- First, create a helper function that bypasses RLS to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  user_role INTEGER;
BEGIN
  SELECT role_id INTO user_role
  FROM users
  WHERE user_id::uuid = user_uuid;
  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy 1: Allow service role (backend) to do everything
CREATE POLICY "Service role has full access to users"
ON users
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy 2: Allow authenticated users to read their own profile
CREATE POLICY "Users can view their own profile"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = user_id::uuid);

-- Policy 3: Allow authenticated users to update their own profile
CREATE POLICY "Users can update their own profile"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id::uuid)
WITH CHECK (auth.uid() = user_id::uuid);

-- Policy 4: Allow admins (role_id = 0) to read all users
CREATE POLICY "Admins can view all users"
ON users
FOR SELECT
TO authenticated
USING (get_user_role(auth.uid()) = 0);

-- Policy 5: Allow managers (role_id = 1) to read all users
CREATE POLICY "Managers can view all users"
ON users
FOR SELECT
TO authenticated
USING (get_user_role(auth.uid()) = 1);

-- Policy 6: Allow admins to insert new users
CREATE POLICY "Admins can insert users"
ON users
FOR INSERT
TO authenticated
WITH CHECK (get_user_role(auth.uid()) = 0);

-- Policy 7: Allow admins to update any user
CREATE POLICY "Admins can update any user"
ON users
FOR UPDATE
TO authenticated
USING (get_user_role(auth.uid()) = 0)
WITH CHECK (get_user_role(auth.uid()) = 0);

-- Policy 8: Allow admins to delete users
CREATE POLICY "Admins can delete users"
ON users
FOR DELETE
TO authenticated
USING (get_user_role(auth.uid()) = 0);

-- Policy 9: Allow authenticated users to insert (for signup/borrow users)
-- This allows any authenticated user to create user records
CREATE POLICY "Allow authenticated inserts for user creation"
ON users
FOR INSERT
TO authenticated
WITH CHECK (true);
