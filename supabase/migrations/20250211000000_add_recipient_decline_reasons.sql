-- Причины отклонения приглашения: recipient_id -> текст ("Не могу прийти", "Перенести на ..." и т.д.)
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS recipient_decline_reasons jsonb NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.events.recipient_decline_reasons IS 'Причины отклонения: { "recipient_id": "текст причины" }';
