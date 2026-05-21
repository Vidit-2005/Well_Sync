# send-patient-push

Remote APNs push sender for patient notifications.

## Deploy

```bash
supabase functions deploy send-patient-push --no-verify-jwt
```

## Required secrets

```bash
supabase secrets set APNS_KEY_ID=YOUR_KEY_ID
supabase secrets set APNS_TEAM_ID=YOUR_TEAM_ID
supabase secrets set APNS_BUNDLE_ID=com.your.bundleid
supabase secrets set APNS_PRIVATE_KEY="$(cat AuthKey_XXXXXX.p8)"
supabase secrets set APNS_USE_SANDBOX=true
```

Set `APNS_USE_SANDBOX=false` for production/TestFlight builds that use production APNs.

## Required table

```sql
create table if not exists public.device_push_tokens (
  token text primary key,
  platform text not null default 'ios',
  role text not null,
  patient_id uuid null references public.patients(patient_id) on delete cascade,
  doctor_id uuid null references public.doctors(doc_id) on delete cascade,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists idx_device_push_tokens_patient
  on public.device_push_tokens(patient_id)
  where is_active = true;
```
