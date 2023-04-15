-- this file was manually created
INSERT INTO public.users (display_name, email,handle, cognito_user_id)
VALUES
  ('Mohammed Firdous','mohammedfirdousaraoye@gmail.com' , 'Fird2307' ,'d7fef980-4fa9-459f-aec4-f067d5e56121');
  ('Andrew Bayko', 'bayko@exampro.co' ,'bayko', 'MOCK'); 
  ('Londo Mollari', 'lmollari@centari.com','londo','MOCK');


INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
