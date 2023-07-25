  -- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Mohammed Firdous','mohammedfirdousaraoye@gmail.com' , 'Firdous' ,'MOCK'),
  ('Alt Firdous','altfirdous@cloudprojectbootcamp.com' , 'AltFirdous' ,'MOCK'),
  ('Andrew Bayko','bayko@cloudprojectbootcamp.com' , 'bayko' ,'MOCK'),
  ('Londo Mollari','lmollari@centari.com' ,'londo' ,'MOCK'); 


INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Firdous' LIMIT 1),
    'This was imported as seed data!',
        current_timestamp + interval '10 day'
  ),
  (
    (SELECT uuid from public.users WHERE users.handle = 'altbrown' LIMIT 1),
    'I am the new user!',
    current_timestamp + interval '10 day'
  )
