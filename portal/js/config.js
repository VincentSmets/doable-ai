// ============================================================
// Doable AI — Supabase Configuratie
// Vul in na aanmaken van je Supabase project:
// Dashboard → Settings → API
// ============================================================

const SUPABASE_URL  = 'https://coipzpplkbksuoijueie.supabase.co';
const SUPABASE_ANON = 'sb_publishable_3PNL_os4z6OL4ck-7jAO7g_ciXkn3Ck';

// Stripe publishable key (vul in na Stripe setup)
const STRIPE_PK = 'pk_test_JOUW-STRIPE-PUBLISHABLE-KEY';

// ============================================================
// Initialiseer Supabase client (geladen via CDN in elke pagina)
// ============================================================
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
