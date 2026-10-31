-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  username text,
  password text,
  nic text UNIQUE,
  first_name text,
  last_name text,
  address text,
  date_of_birth text,
  phone text,
  city_id uuid DEFAULT gen_random_uuid(),
  province_id uuid DEFAULT gen_random_uuid(),
  district_id uuid DEFAULT gen_random_uuid(),
  location jsonb,
  role text,
  profile_completed boolean DEFAULT false,
  phone_verified boolean DEFAULT false,
  is_verified boolean DEFAULT false,
  status text DEFAULT 'PENDING'::text,
  profile_photo_url text,
  gender text,
  last_login timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  token_version integer DEFAULT 1,
  city_geo_location jsonb,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id),
  CONSTRAINT users_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id)
);
CREATE TABLE public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id text NOT NULL,
  phone jsonb NOT NULL,
  legal_name text NOT NULL,
  acronym text NOT NULL,
  type text NOT NULL,
  parent_organisation_id uuid,
  status text NOT NULL DEFAULT 'NULL'::text,
  registration_number text NOT NULL,
  email text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT organizations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.hospitals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  location jsonb NOT NULL,
  phone jsonb NOT NULL,
  license_number text NOT NULL,
  type text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL,
  province_id uuid DEFAULT gen_random_uuid(),
  district_id uuid DEFAULT gen_random_uuid(),
  has_blood_bank boolean DEFAULT false,
  walk_in_donations boolean DEFAULT false,
  parent_blood_bank_id uuid DEFAULT gen_random_uuid(),
  max_capacity_units bigint,
  CONSTRAINT hospitals_pkey PRIMARY KEY (id)
);
CREATE TABLE public.admin_users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text,
  hospital_id uuid,
  org_id uuid,
  is_verified boolean DEFAULT false,
  status text,
  profile_completed boolean DEFAULT false,
  profile_picture_url text DEFAULT 'false'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  user_id uuid,
  CONSTRAINT admin_users_pkey PRIMARY KEY (id),
  CONSTRAINT admin_user_hospital_id_fkey FOREIGN KEY (hospital_id) REFERENCES public.hospitals(id),
  CONSTRAINT admin_user_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT admin_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.hospital_staff (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  hospital_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid DEFAULT gen_random_uuid(),
  type text,
  status text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  CONSTRAINT hospital_staff_pkey PRIMARY KEY (id),
  CONSTRAINT hospital_staff_hospital_id_fkey FOREIGN KEY (hospital_id) REFERENCES public.hospitals(id),
  CONSTRAINT hospital_staff_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.org_staff (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid DEFAULT gen_random_uuid(),
  status text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  CONSTRAINT org_staff_pkey PRIMARY KEY (id),
  CONSTRAINT org_staff_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT org_staff_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.blood_donors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT gen_random_uuid(),
  blood_type_id uuid DEFAULT gen_random_uuid(),
  gender_id uuid DEFAULT gen_random_uuid(),
  ethnicity text,
  country text,
  saved_lives bigint,
  blood_liters_donated bigint,
  last_donated timestamp with time zone,
  last_checked_eligibility timestamp with time zone,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  qr_ref_id text DEFAULT ('bcnt'::text || lpad((nextval('donor_qr_ref_seq'::regclass))::text, 3, '0'::text)) UNIQUE,
  qr_data text,
  CONSTRAINT blood_donors_pkey PRIMARY KEY (id),
  CONSTRAINT blood_donor_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT blood_donors_blood_type_id_fkey FOREIGN KEY (blood_type_id) REFERENCES public.blood_types(id),
  CONSTRAINT blood_donors_gender_id_fkey FOREIGN KEY (gender_id) REFERENCES public.genders(id)
);
CREATE TABLE public.blood_types (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  abo_group character varying NOT NULL CHECK (abo_group::text = ANY (ARRAY['A'::character varying, 'B'::character varying, 'AB'::character varying, 'O'::character varying]::text[])),
  rh_factor character varying NOT NULL CHECK (rh_factor::text = ANY (ARRAY['+'::character varying, '-'::character varying]::text[])),
  display_name character varying NOT NULL UNIQUE,
  sort_order smallint NOT NULL UNIQUE,
  CONSTRAINT blood_types_pkey PRIMARY KEY (id)
);
CREATE TABLE public.genders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code character varying NOT NULL UNIQUE,
  display_name character varying NOT NULL UNIQUE,
  sort_order smallint NOT NULL UNIQUE,
  CONSTRAINT genders_pkey PRIMARY KEY (id)
);
CREATE TABLE public.blood_recipients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT gen_random_uuid(),
  blood_type_id uuid DEFAULT gen_random_uuid(),
  gender_id uuid,
  ethnicity text,
  country text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT blood_recipients_pkey PRIMARY KEY (id),
  CONSTRAINT blood_recipients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT blood_recipients_blood_type_id_fkey FOREIGN KEY (blood_type_id) REFERENCES public.blood_types(id),
  CONSTRAINT blood_recipients_gender_id_fkey FOREIGN KEY (gender_id) REFERENCES public.genders(id)
);
CREATE TABLE public.blood_donations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  donor_id uuid NOT NULL DEFAULT gen_random_uuid(),
  donation_date timestamp with time zone DEFAULT now(),
  volume_ml bigint,
  isHospital boolean DEFAULT false,
  isCamp boolean DEFAULT false,
  hospital_id uuid DEFAULT gen_random_uuid(),
  camp_id uuid DEFAULT gen_random_uuid(),
  hemoglobins_level double precision,
  blood_pressure text,
  component_type text,
  status text,
  expiration_date timestamp with time zone,
  storage_location text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT blood_donations_pkey PRIMARY KEY (id),
  CONSTRAINT blood_donations_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.blood_donors(id),
  CONSTRAINT blood_donations_hospital_id_fkey FOREIGN KEY (hospital_id) REFERENCES public.hospitals(id)
);
CREATE TABLE public.blood_camps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  camp_name text NOT NULL,
  isHospital boolean DEFAULT false,
  isOrg boolean DEFAULT false,
  hospital_id uuid DEFAULT gen_random_uuid(),
  org_id uuid DEFAULT gen_random_uuid(),
  contact_person jsonb,
  venue_name text,
  address text,
  city text,
  postal_code text,
  location text,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  status text,
  target_unit_type text,
  target_units bigint,
  preferred_blood_types jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  province_id uuid,
  district_id uuid,
  geo_location jsonb,
  CONSTRAINT blood_camps_pkey PRIMARY KEY (id),
  CONSTRAINT blood_camps_hospital_id_fkey FOREIGN KEY (hospital_id) REFERENCES public.hospitals(id),
  CONSTRAINT blood_camps_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT blood_camps_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id),
  CONSTRAINT blood_camps_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id)
);
CREATE TABLE public.blood_inventory (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_no bigint NOT NULL,
  donation_id uuid,
  current_hospital_id uuid DEFAULT gen_random_uuid(),
  blood_type_id uuid DEFAULT gen_random_uuid(),
  component_type USER-DEFINED,
  volume_ml double precision,
  collected_at timestamp with time zone,
  expiration_date timestamp with time zone,
  storage_location text,
  status USER-DEFINED,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  CONSTRAINT blood_inventory_pkey PRIMARY KEY (id),
  CONSTRAINT blood_inventory_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.blood_donations(id),
  CONSTRAINT blood_inventory_current_hospital_id_fkey FOREIGN KEY (current_hospital_id) REFERENCES public.hospitals(id),
  CONSTRAINT blood_inventory_blood_type_id_fkey FOREIGN KEY (blood_type_id) REFERENCES public.blood_types(id)
);
CREATE TABLE public.blood_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requesting_hospital_id uuid NOT NULL DEFAULT gen_random_uuid(),
  fulfilling_blood_bank_id uuid DEFAULT gen_random_uuid(),
  blood_type_id uuid DEFAULT gen_random_uuid(),
  component_type USER-DEFINED,
  units_requested bigint,
  priority USER-DEFINED,
  status USER-DEFINED,
  patient_reference uuid DEFAULT gen_random_uuid(),
  requested_at timestamp with time zone,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  CONSTRAINT blood_requests_pkey PRIMARY KEY (id),
  CONSTRAINT blood_requests_fulfilling_blood_bank_id_fkey FOREIGN KEY (fulfilling_blood_bank_id) REFERENCES public.hospitals(id),
  CONSTRAINT blood_requests_blood_type_id_fkey FOREIGN KEY (blood_type_id) REFERENCES public.blood_types(id),
  CONSTRAINT blood_requests_patient_reference_fkey FOREIGN KEY (patient_reference) REFERENCES public.blood_recipients(id),
  CONSTRAINT blood_requests_requesting_hospital_id_fkey FOREIGN KEY (requesting_hospital_id) REFERENCES public.hospitals(id)
);
CREATE TABLE public.blood_req_notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT blood_req_notifications_pkey PRIMARY KEY (id)
);
CREATE TABLE public.otp (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  phone text NOT NULL,
  otp_code text NOT NULL,
  purpose text NOT NULL,
  attempts integer DEFAULT 0,
  is_used boolean DEFAULT false,
  expires_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT otp_pkey PRIMARY KEY (id)
);
CREATE TABLE public.provinces (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  province character varying NOT NULL UNIQUE,
  CONSTRAINT provinces_pkey PRIMARY KEY (id)
);
CREATE TABLE public.districts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  district character varying NOT NULL UNIQUE,
  province_id uuid NOT NULL,
  CONSTRAINT districts_pkey PRIMARY KEY (id),
  CONSTRAINT districts_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id)
);
CREATE TABLE public.cities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  city character varying NOT NULL,
  district_id uuid NOT NULL,
  CONSTRAINT cities_pkey PRIMARY KEY (id),
  CONSTRAINT cities_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id)
);
CREATE TABLE public.camp_visit_confirmations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  donor_id uuid NOT NULL DEFAULT gen_random_uuid(),
  blood_camp_id uuid NOT NULL DEFAULT gen_random_uuid(),
  status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT camp_visit_confirmations_pkey PRIMARY KEY (id),
  CONSTRAINT camp_visit_confirmations_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.blood_donors(id),
  CONSTRAINT camp_visit_confirmations_blood_camp_id_fkey FOREIGN KEY (blood_camp_id) REFERENCES public.blood_camps(id)
);
CREATE TABLE public.assigned_staff_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  camp_id uuid NOT NULL,
  staff_id uuid NOT NULL,
  camp_status text NOT NULL DEFAULT 'ongoing',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT assigned_staff_members_pkey PRIMARY KEY (id),
  CONSTRAINT assigned_staff_members_camp_id_fkey FOREIGN KEY (camp_id) REFERENCES public.blood_camps(id) ON DELETE CASCADE
);