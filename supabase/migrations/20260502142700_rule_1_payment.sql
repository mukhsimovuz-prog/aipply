-- 1. Jurnal uchun jadval
CREATE TABLE IF NOT EXISTS public.system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name TEXT,
    description TEXT,
    related_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Adminlar loglarni ko'ra oladi" ON public.system_logs FOR ALL USING (public.get_my_role() = 'administrator');

-- 2. QOIDA: To'lov muvaffaqiyatli o'tganda ishlaydigan funksiya
CREATE OR REPLACE FUNCTION public.handle_successful_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_yaroqlilik_muddati TIMESTAMPTZ;
BEGIN
  -- Faqat holat 'muvaffaqiyatli' ga o'zgarganda ishlaydi
  IF (TG_OP = 'INSERT' AND NEW.holati = 'muvaffaqiyatli') OR 
     (TG_OP = 'UPDATE' AND NEW.holati = 'muvaffaqiyatli' AND OLD.holati IS DISTINCT FROM 'muvaffaqiyatli') THEN
     
     -- 1. Kurs uchun ruxsat (1 oylik)
     v_yaroqlilik_muddati := NOW() + INTERVAL '30 days';
     INSERT INTO public.foydalanuvchi_kurs_ruxsatlari (foydalanuvchi_id, kurs_id, tolov_id, sotib_olingan_sana, yaroqlilik_muddati, faolmi)
     VALUES (NEW.foydalanuvchi_id, NEW.kurs_id, NEW.id, NOW(), v_yaroqlilik_muddati, true);
     
     -- 2. Mijozga xushxabar (Bildirishnoma)
     INSERT INTO public.bildirishnomalar (foydalanuvchi_id, turi, sarlavha, matn, bogliq_id)
     VALUES (NEW.foydalanuvchi_id, 'tolov_tasdiqi', 'To''lov tasdiqlandi 🎉', 'Sizning ' || NEW.summa || ' so''m miqdoridagi to''lovingiz qabul qilindi va Kursga ruxsat ochildi. Omad!', NEW.kurs_id);
     
     -- 3. Jurnalga yozish (Logging)
     INSERT INTO public.system_logs (rule_name, description, related_id)
     VALUES ('payment_success', 'To''lov ' || NEW.id || ' qabul qilindi. Kurs ochildi.', NEW.id);

  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger yaratish
DROP TRIGGER IF EXISTS on_payment_success ON public.tolovlar;
CREATE TRIGGER on_payment_success
  AFTER INSERT OR UPDATE ON public.tolovlar
  FOR EACH ROW EXECUTE PROCEDURE public.handle_successful_payment();
