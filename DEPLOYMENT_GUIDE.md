# 🚀 Hướng Dẫn Deploy Flutter Web App

## ✅ Bước 1: Build App (Đã Hoàn Thành)

```powershell
flutter build web --release
```

Build output: `build\web\` ✓

---

## 📦 Bước 2: Chọn Nền Tảng Hosting

### **Option A: Firebase Hosting** (Khuyên Dùng - Miễn Phí & Nhanh)

#### 1. Install Firebase CLI
```powershell
npm install -g firebase-tools
```

#### 2. Login to Firebase
```powershell
firebase login
```

#### 3. Initialize Firebase
```powershell
firebase init hosting
```

**Chọn:**
- Use existing project or create new
- Public directory: `build/web`
- Configure as SPA: `Yes`
- Setup automatic builds: `No`

#### 4. Deploy
```powershell
firebase deploy --only hosting
```

**URL:** `https://your-project-id.web.app`

---

### **Option B: GitHub Pages** (Miễn Phí)

#### 1. Create GitHub repository
```powershell
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/username/repo-name.git
git push -u origin main
```

#### 2. Create GitHub Actions workflow

Tạo file `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - run: flutter pub get
      - run: flutter build web --release --base-href /repo-name/
      
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

#### 3. Enable GitHub Pages
- Vào Settings → Pages
- Source: gh-pages branch
- Save

**URL:** `https://username.github.io/repo-name/`

---

### **Option C: Vercel** (Miễn Phí & Rất Nhanh)

#### 1. Install Vercel CLI
```powershell
npm install -g vercel
```

#### 2. Deploy
```powershell
cd build\web
vercel
```

Hoặc import từ GitHub:
1. Vào https://vercel.com
2. Import repository
3. Framework: Other
4. Build Command: `flutter build web`
5. Output Directory: `build/web`

**URL:** `https://your-app.vercel.app`

---

### **Option D: Netlify** (Miễn Phí)

#### Method 1: Drag & Drop (Đơn Giản Nhất)
1. Vào https://app.netlify.com/drop
2. Kéo thả folder `build\web`
3. Done!

#### Method 2: Netlify CLI
```powershell
npm install -g netlify-cli
netlify login
netlify deploy --dir=build/web --prod
```

**URL:** `https://your-app.netlify.app`

---

### **Option E: Supabase Hosting** (Vì Bạn Đã Dùng Supabase)

#### 1. Install Supabase CLI
```powershell
npm install -g supabase
```

#### 2. Login
```powershell
supabase login
```

#### 3. Deploy
```powershell
supabase hosting deploy build/web
```

---

## 🔧 Bước 3: Cấu Hình Environment Variables

### Tạo file `.env` cho production:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Update trong code (nếu cần):

**lib/main.dart:**
```dart
await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);
```

---

## 🌐 Bước 4: Custom Domain (Optional)

### Firebase Hosting:
```powershell
firebase hosting:channel:deploy production --expires never
```

Add domain in Firebase Console → Hosting → Add custom domain

### Vercel/Netlify:
- Vào Dashboard
- Settings → Domains
- Add custom domain
- Update DNS records

---

## ✅ Checklist Trước Khi Deploy

- [ ] Đã test app trên localhost
- [ ] Đã fix tất cả errors
- [ ] Đã cập nhật Supabase URL & Keys
- [ ] Đã build production (`flutter build web --release`)
- [ ] Đã test build trong `build\web\index.html`
- [ ] Đã setup CORS trong Supabase (nếu cần)
- [ ] Đã cấu hình RLS policies

---

## 🔒 Bảo Mật

### 1. Supabase RLS Policies
Đảm bảo đã enable Row Level Security cho tất cả tables:

```sql
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- etc...
```

### 2. Environment Variables
**KHÔNG** commit API keys vào Git. Use:
- GitHub Secrets (cho GitHub Actions)
- Vercel Environment Variables
- Netlify Environment Variables

### 3. CORS Configuration
Trong Supabase Dashboard → Settings → API:
- Add allowed origins: `https://your-domain.com`

---

## 📊 Monitoring & Analytics

### Setup Google Analytics (Optional)
1. Tạo GA4 property
2. Add tracking code vào `web/index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

---

## 🚨 Troubleshooting

### Issue: CORS Error
**Solution:** Add domain to Supabase allowed origins

### Issue: Blank Page
**Solution:** 
- Check browser console for errors
- Verify Supabase credentials
- Check `flutter build web` output for errors

### Issue: 404 on Refresh
**Solution:** Configure SPA routing:
- Firebase: Already handled in `firebase.json`
- Netlify: Create `build/web/_redirects`:
  ```
  /*    /index.html   200
  ```
- Vercel: Create `vercel.json`:
  ```json
  {
    "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
  }
  ```

---

## 🎯 Khuyến Nghị Của Tôi

**Cho Dự Án Tốt Nghiệp:**
1. **Firebase Hosting** - Uy tín, miễn phí, fast
2. **GitHub Pages** - Miễn phí, dễ setup với GitHub repo
3. **Vercel** - Rất nhanh, UI đẹp, CI/CD tự động

**Deploy ngay:**
```powershell
# Firebase (Recommended)
firebase init hosting
firebase deploy

# Hoặc Vercel (Nhanh nhất)
cd build\web
vercel
```

---

## 📝 Ghi Chú

- Build size: ~2-5 MB (đã optimize)
- Load time: 1-3 giây (first load)
- Free tier limits:
  - Firebase: 10 GB storage, 360 MB/day transfer
  - Vercel: Unlimited bandwidth
  - Netlify: 100 GB/month
  - GitHub Pages: 1 GB size limit

---

## 🎓 Demo URL Examples

```
Firebase:   https://medical-equipment-xxx.web.app
Vercel:     https://medical-equipment.vercel.app
Netlify:    https://medical-equipment.netlify.app
GitHub:     https://username.github.io/medical-equipment/
```

Chọn một platform và deploy ngay! 🚀
