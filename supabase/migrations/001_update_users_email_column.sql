-- Migration: Update users table email column to NOT NULL
-- This ensures every user has an email address

-- Step 1: First, ensure all existing users have an email
-- If any users have null emails, they will be updated with a placeholder
UPDATE users 
SET email = user_name || '@placeholder.local'
WHERE email IS NULL OR email = '';

-- Step 2: Make the email column NOT NULL
ALTER TABLE users 
ALTER COLUMN email SET NOT NULL;

-- Step 3: Add a unique constraint on email if not already exists
-- This prevents duplicate emails in the system
ALTER TABLE users 
ADD CONSTRAINT users_email_unique UNIQUE (email);

-- Step 4: Add an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Optional: Add a check constraint to ensure email format is valid
-- Uncomment if you want to enforce email format at database level
-- ALTER TABLE users 
-- ADD CONSTRAINT email_format_check 
-- CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
