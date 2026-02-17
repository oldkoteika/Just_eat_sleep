-- Fit App: схема для синхронизации совместных событий (приглашения на тренировки).
-- Запуск: Supabase Dashboard → SQL Editor → вставить и выполнить по частям или целиком.

-- =============================================================================
-- 1. Таблица profiles (связка auth.uid() ↔ app_uuid приложения)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  app_uuid text NOT NULL UNIQUE,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'Связка сессии Supabase (auth.uid()) и UUID приложения (QR, друзья, события).';

-- Триггер: создавать запись в profiles при регистрации нового пользователя (signUp)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, app_uuid, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'app_uuid', NEW.id::text),
    COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Обновление updated_at при изменении профиля
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: пользователь видит и правит только свой профиль
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- =============================================================================
-- 2. Вспомогательная функция: app_uuid текущей сессии (для RLS на events)
--    Создаётся после profiles, т.к. ссылается на public.profiles.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.current_app_uuid()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT app_uuid FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- =============================================================================
-- 3. Таблица events (совместные события — приглашения, обновления, отмены)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY,
  type text NOT NULL CHECK (type IN ('workout_invitation', 'event_update', 'event_cancellation')),
  workout_name text NOT NULL CHECK (workout_name IN ('legs', 'shoulders', 'chest', 'back', 'arms', 'cardio', 'other')),
  date timestamptz NOT NULL,
  location text,
  description text,
  duration int NOT NULL,
  sender_id text NOT NULL,
  sender_name text NOT NULL,
  recipients text[] NOT NULL DEFAULT '{}',
  recipient_responses jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed')),
  reminder_time int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.events IS 'Совместные события (приглашения на тренировки); синхронизация с приложением.';
COMMENT ON COLUMN public.events.recipient_responses IS 'Объект { "recipient_id": "accepted" | "declined" | "pending" }';

-- Индексы
CREATE INDEX IF NOT EXISTS idx_events_sender_id ON public.events (sender_id);
CREATE INDEX IF NOT EXISTS idx_events_recipients ON public.events USING GIN (recipients);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events (date);

-- Триггер updated_at
DROP TRIGGER IF EXISTS events_updated_at ON public.events;
CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- 4. RLS на events
-- =============================================================================
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- SELECT: отправитель или один из получателей
CREATE POLICY "Events: select if sender or recipient"
  ON public.events FOR SELECT
  USING (
    sender_id = public.current_app_uuid()
    OR public.current_app_uuid() = ANY(recipients)
  );

-- INSERT: только от своего имени (sender_id = текущий app_uuid)
CREATE POLICY "Events: insert as sender"
  ON public.events FOR INSERT
  WITH CHECK (sender_id = public.current_app_uuid());

-- UPDATE: отправитель может менять всё; получатель — только свою запись в recipient_responses (контроль в приложении)
CREATE POLICY "Events: update if sender or recipient"
  ON public.events FOR UPDATE
  USING (
    sender_id = public.current_app_uuid()
    OR public.current_app_uuid() = ANY(recipients)
  );

-- DELETE: только отправитель
CREATE POLICY "Events: delete only sender"
  ON public.events FOR DELETE
  USING (sender_id = public.current_app_uuid());
