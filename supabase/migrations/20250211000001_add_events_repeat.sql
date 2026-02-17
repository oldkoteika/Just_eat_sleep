-- Поле периодичности повторения тренировки: после окончания при repeat != 'never' создаётся следующее событие.
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS repeat text DEFAULT 'never'
  CHECK (repeat IS NULL OR repeat IN ('never', 'weekly', 'biweekly', 'monthly'));

COMMENT ON COLUMN public.events.repeat IS 'Периодичность: never, weekly, biweekly, monthly. После окончания тренировки при повторении создаётся следующее событие.';
