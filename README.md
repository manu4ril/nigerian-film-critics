# Nigerian Film Critics

Production deployment for Vercel + Supabase.

Set Vercel environment variables SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY. Run supabase-schema.sql in Supabase SQL Editor, create an Auth user, and insert that user UUID into public.admins. Import this repository into Vercel; pushes to main deploy automatically.
