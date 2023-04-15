SELECT 
  users.handle
FROM public.users
WHERE 
  %(cognito_user_id)s
  LIMIT 1