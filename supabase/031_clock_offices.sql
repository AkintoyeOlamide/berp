-- BERP approved clock-in offices.
-- Staff may clock in only at these active sites (150 m default).

-- Deactivate any previous pins so only the named offices remain active.
update public.clock_locations
set is_active = false
where app_id = 'berp';

-- LOS HQ OFFICE (Ikeja GRA — formerly 47a Oduduwa Crescent)
insert into public.clock_locations (
  app_id, name, address, latitude, longitude, radius_meters, is_active
)
select
  'berp',
  'LOS HQ OFFICE',
  '47a Oduduwa Crescent, Ikeja GRA, Lagos',
  6.5729595,
  3.3523593,
  150,
  true
where not exists (
  select 1 from public.clock_locations
  where app_id = 'berp' and name = 'LOS HQ OFFICE'
);

update public.clock_locations
set
  address = '47a Oduduwa Crescent, Ikeja GRA, Lagos',
  latitude = 6.5729595,
  longitude = 3.3523593,
  radius_meters = 150,
  is_active = true
where app_id = 'berp' and name = 'LOS HQ OFFICE';

-- Also rename any leftover Ikeja seed row to LOS HQ OFFICE.
update public.clock_locations
set
  name = 'LOS HQ OFFICE',
  address = '47a Oduduwa Crescent, Ikeja GRA, Lagos',
  latitude = 6.5729595,
  longitude = 3.3523593,
  radius_meters = 150,
  is_active = true
where app_id = 'berp'
  and (
    name ilike '%Oduduwa%'
    or name ilike '%Ikeja GRA%'
    or (abs(latitude - 6.5729595) < 0.0002 and abs(longitude - 3.3523593) < 0.0002)
  )
  and name is distinct from 'LOS HQ OFFICE';

-- ABV OFFICE — Riverpark Estate, Abuja
insert into public.clock_locations (
  app_id, name, address, latitude, longitude, radius_meters, is_active
)
select
  'berp',
  'ABV OFFICE',
  'Plot 3586, Cadastral Zone E, Margret Odili Crescent, Cluster 4/062, Riverpark Estate, Abuja, FCT',
  8.94743,
  7.33386,
  150,
  true
where not exists (
  select 1 from public.clock_locations
  where app_id = 'berp' and name = 'ABV OFFICE'
);

update public.clock_locations
set
  address = 'Plot 3586, Cadastral Zone E, Margret Odili Crescent, Cluster 4/062, Riverpark Estate, Abuja, FCT',
  latitude = 8.94743,
  longitude = 7.33386,
  radius_meters = 150,
  is_active = true
where app_id = 'berp' and name = 'ABV OFFICE';

-- LOS CREW HOUSE — Maryland
insert into public.clock_locations (
  app_id, name, address, latitude, longitude, radius_meters, is_active
)
select
  'berp',
  'LOS CREW HOUSE',
  '1 Sanya Ogunbanjo Street, Arowojobe Estate, Mende, Maryland, Lagos',
  6.5695,
  3.3755,
  150,
  true
where not exists (
  select 1 from public.clock_locations
  where app_id = 'berp' and name = 'LOS CREW HOUSE'
);

update public.clock_locations
set
  address = '1 Sanya Ogunbanjo Street, Arowojobe Estate, Mende, Maryland, Lagos',
  latitude = 6.5695,
  longitude = 3.3755,
  radius_meters = 150,
  is_active = true
where app_id = 'berp' and name = 'LOS CREW HOUSE';

-- LOS AIRPORT OFFICE — Murtala Muhammed Airport (Crypt Cafe / Ezumajets area)
insert into public.clock_locations (
  app_id, name, address, latitude, longitude, radius_meters, is_active
)
select
  'berp',
  'LOS AIRPORT OFFICE',
  'Murtala Muhammed International Airport area, Baba Ponmile Street, Ikeja, Lagos',
  6.5767897,
  3.3256025,
  150,
  true
where not exists (
  select 1 from public.clock_locations
  where app_id = 'berp' and name = 'LOS AIRPORT OFFICE'
);

update public.clock_locations
set
  address = 'Murtala Muhammed International Airport area, Baba Ponmile Street, Ikeja, Lagos',
  latitude = 6.5767897,
  longitude = 3.3256025,
  radius_meters = 150,
  is_active = true
where app_id = 'berp' and name = 'LOS AIRPORT OFFICE';

-- Re-assert only these four remain active.
update public.clock_locations
set is_active = false
where app_id = 'berp'
  and name not in (
    'LOS HQ OFFICE',
    'ABV OFFICE',
    'LOS CREW HOUSE',
    'LOS AIRPORT OFFICE'
  );

notify pgrst, 'reload schema';
