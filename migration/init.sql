-- Main Leads
CREATE TABLE leads (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  whatsapp_number text NOT NULL,
  name text,
  email text,
  phone text,
  city text,
  address text,
  stage text DEFAULT 'welcome', -- tracks where the bot stopped
  created_at timestamptz DEFAULT now()
);

-- Project Details
CREATE TABLE projects (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id uuid REFERENCES leads(id),
  project_type text,          -- one of 5 options or 'other'
  access text,
  briefing jsonb,             -- multiple answers (beach? waterfall? etc.)
  area_only boolean,
  base_budget numeric,
  status text DEFAULT 'qualifying'
);

-- Uploaded Files
CREATE TABLE files (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id uuid REFERENCES projects(id),
  url text,
  file_type text,             -- pdf, photo, drone, sketchup
  created_at timestamptz DEFAULT now()
);

-- Technical Visits
CREATE TABLE site_visits (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id uuid REFERENCES projects(id),
  visitor_name text,
  phone text,
  city text,
  scheduled_at timestamptz,
  status text DEFAULT 'pending'
);

-- Message Log (optional, for audit)
CREATE TABLE messages (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  lead_id uuid REFERENCES leads(id),
  direction text,             -- 'in' | 'out'
  content text,
  raw jsonb,
  created_at timestamptz DEFAULT now()
);
