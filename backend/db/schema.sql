create table if not exists app_settings (
  id integer primary key default 1,
  free_signal_limit integer not null default 2,
  reset_period text not null default 'daily',
  distribution_mode text not null default 'first_x_free',
  exness_partner_link text not null,
  updated_at timestamptz not null default now(),
  constraint one_settings_row check (id = 1)
);

create table if not exists signals (
  id uuid primary key,
  source text not null default 'telegram',
  audience text not null check (audience in ('free', 'vip')),
  signal_number integer not null,
  symbol text not null,
  direction text not null check (direction in ('BUY', 'SELL')),
  entry text,
  stop_loss text,
  take_profits jsonb not null default '[]'::jsonb,
  raw_text text not null,
  status text not null default 'active',
  created_at timestamptz not null default now()
);

create table if not exists vip_requests (
  id uuid primary key,
  email text not null,
  display_name text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists users (
  id uuid primary key,
  email text not null unique,
  display_name text,
  password_hash text not null,
  auth_token text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists device_tokens (
  id uuid primary key,
  user_email text not null,
  token text not null unique,
  platform text not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists signals_audience_created_at_idx on signals (audience, created_at desc);
create index if not exists vip_requests_status_created_at_idx on vip_requests (status, created_at desc);
create index if not exists users_auth_token_idx on users (auth_token);
create index if not exists device_tokens_user_email_idx on device_tokens (user_email);
