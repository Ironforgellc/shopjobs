# ShopJobs — Deployment Guide

## What you need before starting
- Supabase project URL + anon key (already have these)
- Vercel account (vercel.com — free)
- GitHub account (free — Vercel deploys from GitHub)

---

## Step 1 — Set up the database

1. Go to your Supabase project dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **New query**
4. Copy the entire contents of `schema.sql` and paste it in
5. Click **Run**
6. You should see "Success" with no errors

---

## Step 2 — Create your admin user

1. In Supabase, go to **Authentication → Users**
2. Click **Add user → Create new user**
3. Enter your email and a password
4. After creating, click the user, then click **Edit**
5. Under **User metadata**, add:
   ```json
   { "role": "admin" }
   ```
6. Save

To add employee accounts, create users the same way but leave the metadata empty (no admin role). They'll be able to update task status but not add orders.

---

## Step 3 — Push to GitHub

1. Create a new repository on github.com (private is fine)
2. In your terminal, from the `shopjobs` folder:
   ```
   git init
   git add .
   git commit -m "Initial ShopJobs build"
   git remote add origin https://github.com/YOUR_USERNAME/shopjobs.git
   git push -u origin main
   ```

---

## Step 4 — Deploy to Vercel

1. Go to vercel.com and sign in
2. Click **Add New → Project**
3. Import your GitHub repository
4. Under **Environment Variables**, add:
   - `REACT_APP_SUPABASE_URL` = `https://swopxsstbthmltxftmzx.supabase.co`
   - `REACT_APP_SUPABASE_ANON_KEY` = your anon key
5. Click **Deploy**
6. Vercel will build and give you a URL like `shopjobs-abc123.vercel.app`

---

## Step 5 — (Optional) Custom domain

1. In Vercel, go to your project → **Settings → Domains**
2. Add your domain (e.g. `jobs.envirodyne.com`)
3. Follow Vercel's instructions to update your DNS records

---

## Using the app

### Loading a new order (admin only)
1. Sign in with your admin account
2. Click **+ New order**
3. Upload the BOM PDF and any drawing PDFs
4. Enter your Anthropic API key (sk-ant-...) — this is used to parse the BOM
5. Click **Parse BOM with Claude**
6. Review the proposed job structure
   - Check/uncheck items as needed
   - Toggle work centers for each job
7. Click **Confirm & create order**
8. The order appears on the dashboard immediately

### Updating status (all users)
1. Click any order on the dashboard
2. Switch between **Task board** and **Cut list**
3. Tap the three-button status controls (To do / In progress / Done)
4. Changes save instantly and sync across all devices in real time

---

## Adding drawing links later

When you have PDF links from Google Drive:
1. Go to Supabase → Table Editor → jobs
2. Find the job row
3. Paste the Google Drive sharing link into the `dwg_url` column
4. The drawing button in the app will now open the PDF directly

---

## Anthropic API key in production

The current build asks for the API key when loading each order. For a more permanent setup:
1. Add `REACT_APP_ANTHROPIC_KEY` to your Vercel environment variables
2. Update `src/lib/claude.js` to use `process.env.REACT_APP_ANTHROPIC_KEY`
3. Remove the API key field from the NewOrder form

Note: Storing the API key in Vercel environment variables exposes it client-side (it starts with REACT_APP_). For production security, set up a Vercel Edge Function to proxy Anthropic calls server-side. Happy to build that when you're ready.
