// ============================================================
// Doable AI — Supabase Configuratie
// Vul in na aanmaken van je Supabase project:
// Dashboard → Settings → API
// ============================================================

const SUPABASE_URL  = 'https://JOUW-PROJECT-ID.supabase.co';
const SUPABASE_ANON = 'JOUW-ANON-PUBLIC-KEY';

// Stripe publishable key (vul in na Stripe setup)
const STRIPE_PK = 'pk_test_JOUW-STRIPE-PUBLISHABLE-KEY';

// ============================================================
// Initialiseer Supabase client (geladen via CDN in elke pagina)
// ============================================================
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
