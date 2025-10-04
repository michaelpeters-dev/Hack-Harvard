# 🚀 Deployment Guide

## Overview
You need to deploy 2 components:
1. **Web App** → Vercel (Next.js)
2. **Socket.IO Server** → Railway (Node.js)

---

## Part 1: Deploy Web App to Vercel

### Option A: Deploy via Vercel CLI (Recommended)

**Step 1: Install Vercel CLI**
```bash
npm install -g vercel
```

**Step 2: Login to Vercel**
```bash
vercel login
```

**Step 3: Deploy from web-helper directory**
```bash
cd web-helper
vercel
```

Follow the prompts:
- Setup and deploy? **Y**
- Which scope? Select your account
- Link to existing project? **N**
- Project name? **vision-pro-helper** (or any name)
- Directory? **./web-helper** or just press Enter
- Override settings? **N**

**Step 4: Set Environment Variable**
After first deploy, run:
```bash
vercel env add NEXT_PUBLIC_SOCKET_URL
```
- Enter: `production`
- Value: `https://your-socket-server.railway.app` (we'll get this in Part 2)

**Step 5: Deploy to Production**
```bash
vercel --prod
```

You'll get a URL like: `https://vision-pro-helper.vercel.app`

### Option B: Deploy via Vercel Dashboard

1. Go to https://vercel.com/new
2. Import your GitHub repository
3. Root Directory: `web-helper`
4. Framework Preset: **Next.js**
5. Build Command: `npm run build`
6. Output Directory: `.next`
7. Install Command: `npm install`
8. Add Environment Variable:
   - Name: `NEXT_PUBLIC_SOCKET_URL`
   - Value: `https://your-socket-server.railway.app` (add later)
9. Click **Deploy**

---

## Part 2: Deploy Socket.IO Server to Railway

### Why Railway?
- Easy WebSocket support
- Free tier available
- Simple Node.js deployment
- Automatic HTTPS/WSS

### Step 1: Create Railway Account
Go to https://railway.app and sign up (free tier)

### Step 2: Install Railway CLI
```bash
npm install -g @railway/cli
```

### Step 3: Login
```bash
railway login
```

### Step 4: Create New Project
```bash
cd web-helper/server
railway init
```
- Project name: **vision-pro-signaling**

### Step 5: Add Environment Variables
```bash
railway variables set CORS_ORIGIN=https://your-vercel-app.vercel.app
railway variables set SOCKET_PORT=3001
```

### Step 6: Deploy
```bash
railway up
```

### Step 7: Get Your Railway URL
```bash
railway domain
```
This will give you a URL like: `https://vision-pro-signaling.railway.app`

### Step 8: Update Vercel Environment Variable
Go back to Vercel:
```bash
vercel env add NEXT_PUBLIC_SOCKET_URL production
# Enter the Railway URL
```

Then redeploy:
```bash
vercel --prod
```

---

## Alternative: Deploy Socket.IO to Render

### Step 1: Create Render Account
Go to https://render.com and sign up

### Step 2: Create New Web Service
1. Click **New +** → **Web Service**
2. Connect your GitHub repo
3. Settings:
   - Name: `vision-pro-signaling`
   - Root Directory: `web-helper/server`
   - Runtime: **Node**
   - Build Command: `npm install socket.io`
   - Start Command: `node socket-server.js`
   - Plan: **Free**

### Step 3: Add Environment Variables
In Render dashboard:
- `CORS_ORIGIN`: `https://your-vercel-app.vercel.app`
- `SOCKET_PORT`: `3001`

### Step 4: Deploy
Click **Create Web Service**

You'll get a URL like: `https://vision-pro-signaling.onrender.com`

---

## Part 3: Update Vision Pro App

Update your Vision Pro app configuration to use production URLs:

```swift
// Config.plist or environment config
let socketServerURL = "https://vision-pro-signaling.railway.app"
```

---

## Verification Checklist

### After Deployment:

- [ ] Web app accessible at Vercel URL
- [ ] Socket.IO server responds at Railway/Render URL
- [ ] Open web app in browser
- [ ] Check connection status (should be green)
- [ ] Browser console shows no errors
- [ ] Test with mock Vision Pro client

### Test URLs:

**Web App:**
```
https://your-app.vercel.app
```

**Socket.IO Server Health Check:**
```bash
curl https://your-socket-server.railway.app
```

**WebSocket Test:**
Open browser console on your web app:
```javascript
console.log('Socket connected:', /* check network tab */);
```

---

## Cost Breakdown

### Free Tier (Sufficient for Development)

| Service | Free Tier | Limit |
|---------|-----------|-------|
| **Vercel** | ✓ Free | 100GB bandwidth/month |
| **Railway** | $5 credit/month | ~500 hours/month |
| **Render** | ✓ Free | Sleeps after 15min inactivity |

### Recommended for Production

| Service | Cost | Why |
|---------|------|-----|
| **Vercel Pro** | $20/month | Better performance |
| **Railway Hobby** | $5/month | 500 hours (enough for 24/7) |

---

## Troubleshooting

### Web App Deploys but Shows Connection Error

**Fix:** Update environment variable
```bash
vercel env add NEXT_PUBLIC_SOCKET_URL production
# Enter correct Socket.IO server URL
vercel --prod
```

### Socket.IO Server Shows CORS Error

**Fix:** Update CORS_ORIGIN
```bash
railway variables set CORS_ORIGIN=https://your-actual-vercel-app.vercel.app
```

### WebSocket Connection Fails

**Check:**
1. Socket.IO server is running (visit URL in browser)
2. URL uses `https://` (not `http://`)
3. Vercel env variable is set correctly
4. No firewall blocking WebSocket

**Test WebSocket:**
```javascript
// In browser console on your web app
new WebSocket('wss://your-socket-server.railway.app/socket.io/?EIO=4&transport=websocket')
```

### Railway App Sleeps

**Fix:** Upgrade to Hobby plan ($5/month) for 24/7 uptime

---

## Quick Deploy Commands Summary

**Full deployment in ~5 minutes:**

```bash
# 1. Install CLIs
npm install -g vercel @railway/cli

# 2. Login
vercel login
railway login

# 3. Deploy web app
cd web-helper
vercel --prod

# 4. Deploy Socket.IO server
cd server
railway init
railway up
railway domain

# 5. Update Vercel with Railway URL
vercel env add NEXT_PUBLIC_SOCKET_URL production
# Paste Railway URL
vercel --prod
```

---

## Production URLs

After deployment, you'll have:

**Web Helper:**
```
https://vision-pro-helper.vercel.app
```

**Socket.IO Server:**
```
https://vision-pro-signaling.railway.app
```

**Update these in:**
- Vision Pro app config
- Mobile app config
- Documentation

---

## Next Steps After Deployment

1. ✅ Test with Vision Pro device
2. ✅ Configure TURN server (for production WebRTC)
3. ✅ Add authentication
4. ✅ Set up monitoring (Vercel Analytics, Railway metrics)
5. ✅ Custom domain (optional)

---

## Support

- **Vercel Docs**: https://vercel.com/docs
- **Railway Docs**: https://docs.railway.app
- **Render Docs**: https://render.com/docs

For issues, check:
- Vercel deployment logs
- Railway/Render logs
- Browser console errors
- Network tab (WebSocket frames)

