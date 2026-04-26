// ============================================================
// Doable AI — Supabase Configuratie
// Vul in na aanmaken van je Supabase project:
// Dashboard → Settings → API
// ============================================================

const SUPABASE_URL  = 'https://coipzpplkbksuoijueie.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvaXB6cHBsa2Jrc3VvaWp1ZWllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxNjc4MDQsImV4cCI6MjA5Mjc0MzgwNH0.4fZzaumC5hZlxQttytOiQQKnGa_e5VEgcE3fnhgWCQs';

// Stripe publishable key (vul in na Stripe setup)
const STRIPE_PK = 'pk_test_JOUW-STRIPE-PUBLISHABLE-KEY';

// ============================================================
// Initialiseer Supabase client (geladen via CDN in elke pagina)
// ============================================================
window.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
