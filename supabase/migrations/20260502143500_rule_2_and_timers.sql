-- ==========================================
-- QOIDA 2: Yangi xabar kelganda bildirishnoma yuborish (Harakat bo'yicha)
-- ==========================================
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
  -- Yakka foydalanuvchiga kelgan bo'lsa
  IF NEW.qabul_qiluvchi_turi = 'yakka_foydalanuvchi' AND NEW.qabul_qiluvchi_user_id IS NOT NULL THEN
    INSERT INTO public.bildirishnomalar (foydalanuvchi_id, turi, sarlavha, matn, bogliq_id)
    VALUES (NEW.qabul_qiluvchi_user_id, 'yangi_xabar', 'Sizga yangi xabar', NEW.mavzu, NEW.id);
    
  -- Butun guruhga yozilgan bo'lsa
  ELSIF NEW.qabul_qiluvchi_turi = 'butun_guruh' AND NEW.qabul_qiluvchi_guruh_id IS NOT NULL THEN
    INSERT INTO public.bildirishnomalar (foydalanuvchi_id, turi, sarlavha, matn, bogliq_id)
    SELECT foydalanuvchi_id, 'yangi_xabar', 'Guruhda yangi xabar', NEW.mavzu, NEW.id
    FROM public.foydalanuvchi_guruh
    WHERE guruh_id = NEW.qabul_qiluvchi_guruh_id;
  END IF;

  -- Jurnalga yozish
  INSERT INTO public.system_logs (rule_name, description, related_id)
  VALUES ('new_message_notification', 'Yangi xabar (' || NEW.id || ') uchun bildirishnoma yaratildi.', NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_message ON public.xabarlar;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.xabarlar
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_message();


-- ==========================================
-- TAYMER BO'YICHA QOIDALAR (CRON JOBS)
-- ==========================================

-- pg_cron kengaytmasini yoqamiz (Supabase SQL Editor orqali ishlashi uchun)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 1. Passiv foydalanuvchilarni tekshiruvchi funksiya
CREATE OR REPLACE FUNCTION public.check_inactive_users() RETURNS void AS $$
BEGIN
  INSERT INTO public.bildirishnomalar (foydalanuvchi_id, turi, sarlavha, matn)
  SELECT id, 'dars_eslatma', 'Darslaringizni sog''indingizmi?', 'Kompyuter sirlari sizni kutmoqda! Darsni davom ettiring.'
  FROM public.profiles
  WHERE oxirgi_faollik < NOW() - INTERVAL '3 days';
  
  INSERT INTO public.system_logs (rule_name, description)
  VALUES ('awake_passive_users', '3 kundan beri tizimga kirmagan o''quvchilarga eslatma yuborildi.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Muddati tugayotgan kurslarni tekshiruvchi funksiya
CREATE OR REPLACE FUNCTION public.check_course_expirations() RETURNS void AS $$
BEGIN
  INSERT INTO public.bildirishnomalar (foydalanuvchi_id, turi, sarlavha, matn, bogliq_id)
  SELECT foydalanuvchi_id, 'dars_eslatma', 'Kurs muddati tugamoqda', 'Kursga ruxsatingiz 3 kundan keyin tugaydi. Ulugrib qoling!', kurs_id
  FROM public.foydalanuvchi_kurs_ruxsatlari
  WHERE yaroqlilik_muddati BETWEEN NOW() + INTERVAL '2 days' AND NOW() + INTERVAL '3 days' AND faolmi = true;
  
  INSERT INTO public.system_logs (rule_name, description)
  VALUES ('course_expiration_warning', 'Muddati tugayotgan kurslar bo''yicha ogohlantirishlar yaratildi.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Har kuni ertalab soat 09:00 da (UTC vaqti bilan) ishlashini tayinlash (Schedule)
SELECT cron.schedule('awake_passive_users_job', '0 9 * * *', 'SELECT public.check_inactive_users()');
SELECT cron.schedule('course_expiration_job', '0 9 * * *', 'SELECT public.check_course_expirations()');
