-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Mohammed Firdous','mohammedfirdousaraoye@gmail.com' , 'Fird2307' ,'MOCK'),
  ('Andrew Brown', 'andrewbrown', 'andrewbrown@test.com', 'MOCK'),
  ('Andrew Bayko','bayko@exampro.co' , 'bayko' ,'MOCK'),
  



INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Fird2307' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
