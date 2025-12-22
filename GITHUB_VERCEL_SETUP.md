# 🚀 Deploy to Vercel with GitHub (2 Branches)

## 📋 Overview
- **main branch** → Production (official release)
- **dev branch** → Development (testing, debugging)

---

## Part 1: Setup GitHub Repository

### Step 1: Initialize Git (if not already)
```powershell
# Check if git is initialized
git status

# If not initialized, run:
git init
```

### Step 2: Create .gitignore
```powershell
# Create .gitignore file
New-Item -Path .gitignore -ItemType File -Force
```

Add this content to `.gitignore`:
```
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png

# IDE
.idea/
.vscode/
*.iml
*.swp

# Misc
*.log
*.lock
.DS_Store
.env
.env.local

# Windows
Thumbs.db

# Build outputs
build/
web/
*.js.map
```

### Step 3: Create GitHub Repository
1. Go to https://github.com
2. Click **"New"** button (green button)
3. Repository name: `medical-equipment-management` (or your choice)
4. Description: `Medical Equipment Management System - DATN 2025`
5. Choose **Private** or **Public**
6. **DON'T** check "Initialize with README" (we already have files)
7. Click **"Create repository"**

### Step 4: Connect Local to GitHub
```powershell
# Add remote origin (replace with YOUR GitHub username and repo name)
git remote add origin https://github.com/YOUR_USERNAME/medical-equipment-management.git

# Verify remote
git remote -v
```

---

## Part 2: Create and Setup Branches

### Step 5: Create Main Branch
```powershell
# Stage all files
git add .

# First commit
git commit -m "Initial commit - Medical Equipment Management System"

# Rename default branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

### Step 6: Create Dev Branch
```powershell
# Create and switch to dev branch
git checkout -b dev

# Push dev branch to GitHub
git push -u origin dev

# Switch back to main
git checkout main
```

### Step 7: Verify Branches
```powershell
# List all branches
git branch -a

# Should show:
# * main
#   dev
#   remotes/origin/main
#   remotes/origin/dev
```

---

## Part 3: Deploy to Vercel

### Step 8: Install Vercel CLI (Optional)
```powershell
npm install -g vercel
```

### Step 9: Login to Vercel
1. Go to https://vercel.com
2. Click **"Sign Up"** or **"Login"**
3. Choose **"Continue with GitHub"**
4. Authorize Vercel to access your GitHub

### Step 10: Import Project
1. In Vercel dashboard, click **"Add New..."** → **"Project"**
2. Click **"Import Git Repository"**
3. Select your repository: `medical-equipment-management`
4. Click **"Import"**

### Step 11: Configure Project Settings
```
Framework Preset: Other
Root Directory: ./
Build Command: flutter build web --release
Output Directory: build/web
Install Command: flutter pub get
```

**Environment Variables** (if needed):
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Step 12: Configure Branch Deployments
In Vercel project settings:

1. Go to **Settings** → **Git**
2. **Production Branch**: `main`
   - This will deploy to: `your-app.vercel.app`
3. **Enable Branch Deployments**: ✅ On
   - Dev branch will deploy to: `your-app-git-dev.vercel.app`

### Step 13: Deploy
Click **"Deploy"** button

Wait 2-3 minutes for build to complete ⏳

---

## Part 4: Workflow - How to Use

### 🛠️ Working on Dev Branch (Development)

```powershell
# 1. Switch to dev branch
git checkout dev

# 2. Make changes to your code
# (Edit files, fix bugs, add features)

# 3. Test locally
flutter run -d chrome

# 4. When ready, commit changes
git add .
git commit -m "Add new feature: QR code scanner improvements"

# 5. Push to GitHub (triggers Vercel preview deployment)
git push origin dev
```

**Result:** Changes deployed to `your-app-git-dev.vercel.app` automatically! 🎉

### ✅ Test on Dev URL
1. Open `your-app-git-dev.vercel.app`
2. Test all features
3. Check for bugs
4. Get feedback

### 🚀 Promote to Production (Main Branch)

```powershell
# 1. Switch to main branch
git checkout main

# 2. Merge dev into main
git merge dev

# 3. Push to GitHub (triggers production deployment)
git push origin main
```

**Result:** Changes deployed to `your-app.vercel.app` (production)! 🚀

### 🔄 After Merge, Continue Dev Work

```powershell
# Switch back to dev
git checkout dev

# Continue working...
```

---

## Part 5: Common Git Commands

### Check Current Branch
```powershell
git branch
# * means current branch
```

### Switch Between Branches
```powershell
# To dev
git checkout dev

# To main
git checkout main
```

### See Status
```powershell
git status
```

### See Commit History
```powershell
git log --oneline --graph --all
```

### Pull Latest Changes
```powershell
# Pull from current branch
git pull

# Pull from specific branch
git pull origin main
git pull origin dev
```

### Discard Local Changes
```powershell
# Discard all uncommitted changes
git reset --hard

# Discard specific file
git checkout -- path/to/file.dart
```

---

## Part 6: Vercel Dashboard Features

### View Deployments
- **Production**: main branch deployments
- **Preview**: dev branch deployments
- Each commit creates a new preview URL

### Deployment Status
- ✅ Ready (deployment successful)
- 🔄 Building (in progress)
- ❌ Failed (check logs)

### View Logs
- Click on deployment
- Click **"View Function Logs"** or **"View Build Logs"**
- Check for errors

### Domains
- Production: `your-app.vercel.app`
- Preview: `your-app-git-dev.vercel.app`
- Custom domain: Add in Settings → Domains

---

## Part 7: Branch Protection Rules (Optional)

Protect main branch from direct pushes:

1. Go to GitHub repository
2. **Settings** → **Branches**
3. **Add rule** for `main`
4. Check:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
5. Save

Now you MUST create Pull Request from dev → main (better practice!)

---

## Part 8: Pull Request Workflow (Recommended)

### Instead of Direct Merge, Use PR:

```powershell
# 1. Push dev branch
git checkout dev
git push origin dev
```

### 2. On GitHub:
1. Go to your repository
2. Click **"Pull requests"** tab
3. Click **"New pull request"**
4. Base: `main` ← Compare: `dev`
5. Click **"Create pull request"**
6. Add title & description
7. Click **"Create pull request"**

### 3. Review Changes:
- See all file changes
- Add comments
- Request reviews (if working with team)

### 4. Merge:
- Click **"Merge pull request"**
- Click **"Confirm merge"**
- Vercel automatically deploys to production! 🚀

---

## Part 9: Rollback (If Something Goes Wrong)

### Option A: Revert in Vercel
1. Go to Vercel dashboard
2. Click on previous working deployment
3. Click **"Promote to Production"**

### Option B: Revert in Git
```powershell
# Find the commit you want to revert to
git log --oneline

# Revert to that commit
git revert <commit-hash>

# Push
git push origin main
```

---

## Part 10: Best Practices

### ✅ DO:
- Always test on dev before merging to main
- Write meaningful commit messages
- Commit small, logical changes
- Pull before you push
- Use Pull Requests for main branch

### ❌ DON'T:
- Don't commit sensitive data (API keys, passwords)
- Don't push directly to main (use dev → main flow)
- Don't commit `build/` folder (already in .gitignore)
- Don't force push (`git push -f`) unless absolutely necessary

---

## Part 11: Troubleshooting

### Issue: "error: failed to push some refs"
**Solution:**
```powershell
git pull origin main --rebase
git push origin main
```

### Issue: Vercel build fails
**Solution:**
1. Check build logs in Vercel
2. Test locally: `flutter build web --release`
3. Fix errors
4. Push again

### Issue: Merge conflicts
**Solution:**
```powershell
# 1. Switch to main
git checkout main

# 2. Pull latest
git pull origin main

# 3. Switch to dev
git checkout dev

# 4. Merge main into dev (to update dev)
git merge main

# 5. Fix conflicts in files (look for <<<<<<, ======, >>>>>>)
# 6. After fixing:
git add .
git commit -m "Resolve merge conflicts"
git push origin dev
```

### Issue: Wrong branch
```powershell
# Check current branch
git branch

# Switch to correct branch
git checkout main  # or dev
```

---

## 📊 Deployment URLs Summary

| Branch | Purpose | URL | Auto Deploy |
|--------|---------|-----|-------------|
| `main` | Production (Official) | `your-app.vercel.app` | ✅ Yes |
| `dev` | Development (Testing) | `your-app-git-dev.vercel.app` | ✅ Yes |
| Any PR | Preview | `your-app-git-pr-X.vercel.app` | ✅ Yes |

---

## 🎯 Quick Reference

### Everyday Workflow:
```powershell
# Morning: Start work
git checkout dev
git pull origin dev

# Work on features...
# (edit files)

# Evening: Save work
git add .
git commit -m "Descriptive message"
git push origin dev

# When ready for production:
git checkout main
git merge dev
git push origin main
```

---

## ✅ Checklist

Before you start:
- [ ] GitHub account created
- [ ] Git installed (`git --version`)
- [ ] Repository created on GitHub
- [ ] Vercel account created (with GitHub linked)

After setup:
- [ ] Main branch pushed to GitHub
- [ ] Dev branch created and pushed
- [ ] Vercel project imported
- [ ] Production URL working
- [ ] Dev URL working
- [ ] Tested deployment workflow

---

## 📞 Need Help?

Common commands cheat sheet:
```powershell
git status                    # See what's changed
git branch                    # See current branch
git checkout dev              # Switch to dev
git checkout main             # Switch to main
git add .                     # Stage all changes
git commit -m "Message"       # Commit with message
git push origin dev           # Push to dev
git push origin main          # Push to main
git pull origin dev           # Get latest from dev
git merge dev                 # Merge dev into current branch
git log --oneline             # See commit history
```

Happy coding! 🚀
