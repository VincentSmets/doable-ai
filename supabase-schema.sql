-- ============================================================
-- Doable AI — Supabase Database Schema
-- Plak dit volledig in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- ── EXTENSIONS ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── CLIENTS ─────────────────────────────────────────────────
CREATE TABLE clients (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- portal login account van klant
  company_name  TEXT NOT NULL,
  contact_name  TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT,
  sector        TEXT,
  address       TEXT,
  city          TEXT,
  notes         TEXT,
  status        TEXT NOT NULL DEFAULT 'prospect' CHECK (status IN ('prospect','active','past')),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROJECTS ────────────────────────────────────────────────
CREATE TABLE projects (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'intake' CHECK (status IN ('intake','building','delivered','support','closed')),
  value_eur   NUMERIC(10,2),
  start_date  DATE,
  end_date    DATE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── MESSAGES ────────────────────────────────────────────────
CREATE TABLE messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('admin','client')),
  content     TEXT NOT NULL,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── DOCUMENTS ───────────────────────────────────────────────
CREATE TABLE documents (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  file_path   TEXT NOT NULL,   -- Supabase Storage path: {client_id}/{timestamp}_{filename}
  doc_type    TEXT DEFAULT 'overig',  -- rapport, contract, handleiding, offerte, overig
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── INVOICES ────────────────────────────────────────────────
CREATE TABLE invoices (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id            UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  invoice_number       TEXT NOT NULL UNIQUE,  -- bijv. 2026-001
  description          TEXT NOT NULL,
  amount_eur           NUMERIC(10,2) NOT NULL,
  vat_pct              NUMERIC(5,2) DEFAULT 21.00,
  status               TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','paid','overdue','cancelled')),
  invoice_date         DATE,
  due_date             DATE,
  paid_at              TIMESTAMPTZ,
  stripe_checkout_url  TEXT,   -- betaallink voor klant (Stripe Checkout Session URL)
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROPOSALS (Offertes) ─────────────────────────────────────
CREATE TABLE proposals (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,            -- samenvatting zichtbaar voor klant
  amount_eur  NUMERIC(10,2),
  status      TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','accepted','rejected','expired')),
  expires_at  DATE,            -- geldig tot datum
  doc_url     TEXT,            -- externe link naar offertebestand (Google Drive, PDF etc.)
  accepted_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── UPDATED_AT TRIGGER ───────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clients_updated_at   BEFORE UPDATE ON clients   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER projects_updated_at  BEFORE UPDATE ON projects  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER invoices_updated_at  BEFORE UPDATE ON invoices  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER proposals_updated_at BEFORE UPDATE ON proposals FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── ROW LEVEL SECURITY ───────────────────────────────────────
ALTER TABLE clients   ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects  ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages  ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices  ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;

-- Helper function: is de huidige user admin?
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin',
    FALSE
  );
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper function: geeft de client_id van de ingelogde klant
CREATE OR REPLACE FUNCTION my_client_id()
RETURNS UUID AS $$
  SELECT id FROM clients WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- ── RLS POLICIES: CLIENTS ────────────────────────────────────
CREATE POLICY "admin_all_clients" ON clients
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_record" ON clients
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- ── RLS POLICIES: PROJECTS ──────────────────────────────────
CREATE POLICY "admin_all_projects" ON projects
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_projects" ON projects
  FOR SELECT TO authenticated USING (client_id = my_client_id());

-- ── RLS POLICIES: MESSAGES ──────────────────────────────────
CREATE POLICY "admin_all_messages" ON messages
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_messages" ON messages
  FOR SELECT TO authenticated USING (client_id = my_client_id());

CREATE POLICY "client_send_message" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (client_id = my_client_id() AND sender_role = 'client');

-- ── RLS POLICIES: DOCUMENTS ─────────────────────────────────
CREATE POLICY "admin_all_documents" ON documents
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_documents" ON documents
  FOR SELECT TO authenticated USING (client_id = my_client_id());

-- ── RLS POLICIES: INVOICES ──────────────────────────────────
CREATE POLICY "admin_all_invoices" ON invoices
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_invoices" ON invoices
  FOR SELECT TO authenticated
  USING (client_id = my_client_id() AND status != 'draft');

-- ── RLS POLICIES: PROPOSALS ─────────────────────────────────
CREATE POLICY "admin_all_proposals" ON proposals
  FOR ALL TO authenticated USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "client_own_proposals" ON proposals
  FOR SELECT TO authenticated
  USING (client_id = my_client_id() AND status != 'draft');

CREATE POLICY "client_accept_proposal" ON proposals
  FOR UPDATE TO authenticated
  USING (client_id = my_client_id() AND status = 'sent')
  WITH CHECK (status IN ('accepted','rejected'));

-- ── STORAGE BUCKET ───────────────────────────────────────────
-- 1. Maak een PRIVATE bucket 'documents' aan via:
--    Supabase Dashboard → Storage → New bucket → naam: 'documents' → Private ✓
--
-- 2. Voeg storage policies toe via Storage → Policies → 'documents' bucket:
--
--    Policy 1 — Admin kan alles uploaden/lezen/verwijderen:
--    Naam: "admin_storage_all"
--    Allowed operation: ALL
--    Target roles: authenticated
--    USING: (SELECT is_admin())
--
--    Policy 2 — Klanten kunnen eigen bestanden lezen:
--    Naam: "client_storage_read"
--    Allowed operation: SELECT
--    Target roles: authenticated
--    USING: (storage.foldername(name))[1] = (SELECT id::text FROM clients WHERE user_id = auth.uid() LIMIT 1)

-- ── INDEXES ─────────────────────────────────────────────────
CREATE INDEX idx_clients_user_id   ON clients(user_id);
CREATE INDEX idx_clients_status    ON clients(status);
CREATE INDEX idx_projects_client   ON projects(client_id);
CREATE INDEX idx_messages_client   ON messages(client_id);
CREATE INDEX idx_messages_read     ON messages(client_id, sender_role, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_invoices_client   ON invoices(client_id);
CREATE INDEX idx_invoices_status   ON invoices(status);
CREATE INDEX idx_documents_client  ON documents(client_id);
CREATE INDEX idx_proposals_client  ON proposals(client_id);

-- ── ADMIN USER INSTELLEN ─────────────────────────────────────
-- Stap 1: Maak jouw account aan via Supabase → Authentication → Users → Add user
-- Stap 2: Voer onderstaand query uit (vervang email):

-- UPDATE auth.users
-- SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin", "name": "Vincent"}'::jsonb
-- WHERE email = 'hallo@doable-ai.nl';

-- ── KLANT PORTAAL ACCOUNT KOPPELEN ──────────────────────────
-- Wanneer een klant een account aanmaakt via Supabase Auth,
-- koppel je hun user_id aan het juiste clients record:

-- UPDATE clients
-- SET user_id = (SELECT id FROM auth.users WHERE email = 'klant@email.nl')
-- WHERE email = 'klant@email.nl';

-- ============================================================
-- KLAAR! Controleer in Table Editor of alle tabellen er zijn.
-- ============================================================
