-- Reserve user numbers 1-100 for future employees, donors, etc.
-- Advances the users_user_number_seq so the next auto-assigned number is 101.
-- Existing users keep their current numbers; only new signups are affected.
-- Safe to run even if the sequence is already past 100 (won't go backwards).

SELECT setval(
  'users_user_number_seq',
  GREATEST(100, (SELECT last_value FROM users_user_number_seq)),
  true
);
