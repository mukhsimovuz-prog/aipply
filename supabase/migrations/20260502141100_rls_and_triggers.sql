-- 1. YORDAMCHI FUNKSIYALAR
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS user_role AS $$
  SELECT rol FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 2. AVTOMATIK PROFIL YARATISH TRIGGERI
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, ism, rol)
  VALUES (new.id, new.email, coalesce(new.raw_user_meta_data->>'ism', 'Foydalanuvchi'), 'oquvchi');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 3. TEST NATIJALARINI HISOBLASH (XAVFSIZ FUNKSIYA)
CREATE OR REPLACE FUNCTION public.submit_test_attempt(
  p_test_id UUID,
  p_answers JSONB
) RETURNS UUID AS $$
DECLARE
  v_urinish_id UUID;
  v_togri_javoblar INT := 0;
  v_jami_savollar INT;
  v_foiz DECIMAL;
  v_minimal_ball INT;
  v_muvaffaqiyatlimi BOOLEAN;
  v_kutish_vaqti INT;
  v_ans RECORD;
  v_is_correct BOOLEAN;
BEGIN
  INSERT INTO public.test_urinishlari (foydalanuvchi_id, test_id, boshlangan_vaqt, tugagan_vaqt)
  VALUES (auth.uid(), p_test_id, NOW(), NOW())
  RETURNING id INTO v_urinish_id;

  FOR v_ans IN SELECT * FROM jsonb_to_recordset(p_answers) AS x(savol_id UUID, variant_id UUID) LOOP
    SELECT togrimi INTO v_is_correct FROM public.savol_variantlari WHERE id = v_ans.variant_id;
    INSERT INTO public.test_javoblari (urinish_id, savol_id, tanlangan_variant_id, togrimi)
    VALUES (v_urinish_id, v_ans.savol_id, v_ans.variant_id, COALESCE(v_is_correct, false));
    IF v_is_correct THEN v_togri_javoblar := v_togri_javoblar + 1; END IF;
  END LOOP;

  SELECT count(*) INTO v_jami_savollar FROM public.test_savollari WHERE test_id = p_test_id;
  SELECT minimal_ball, kutish_vaqti INTO v_minimal_ball, v_kutish_vaqti FROM public.testlar WHERE id = p_test_id;
  
  IF v_jami_savollar > 0 THEN v_foiz := (v_togri_javoblar::DECIMAL / v_jami_savollar) * 100; ELSE v_foiz := 0; END IF;
  v_muvaffaqiyatlimi := v_foiz >= COALESCE(v_minimal_ball, 0);

  UPDATE public.test_urinishlari
  SET togri_javoblar_soni = v_togri_javoblar, foiz = v_foiz, muvaffaqiyatlimi = v_muvaffaqiyatlimi,
      keyingi_urinish_vaqti = CASE WHEN NOT v_muvaffaqiyatlimi THEN NOW() + (v_kutish_vaqti || ' minutes')::INTERVAL ELSE NULL END
  WHERE id = v_urinish_id;

  RETURN v_urinish_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. AVTOMATIK SERTIFIKAT BERISH TRIGGERI
CREATE OR REPLACE FUNCTION public.check_and_issue_certificate() 
RETURNS TRIGGER AS $$
DECLARE
  v_kurs_id UUID;
  v_cert_id TEXT;
  v_verify_code TEXT;
  v_daraja certificate_grade;
BEGIN
  IF NEW.muvaffaqiyatlimi = true THEN
    SELECT kurs_id INTO v_kurs_id FROM public.testlar WHERE id = NEW.test_id;
    IF v_kurs_id IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM public.sertifikatlar WHERE foydalanuvchi_id = NEW.foydalanuvchi_id AND kurs_id = v_kurs_id) THEN
        v_cert_id := 'RK-' || to_char(NOW(), 'YYYY') || '-' || upper(substring(uuid_generate_v4()::text from 1 for 4));
        v_verify_code := v_cert_id || '-' || upper(substring(uuid_generate_v4()::text from 1 for 4));
        
        IF NEW.foiz >= 90 THEN v_daraja := 'alo'; ELSIF NEW.foiz >= 80 THEN v_daraja := 'yaxshi'; ELSE v_daraja := 'ortacha'; END IF;

        INSERT INTO public.sertifikatlar (sertifikat_id_kodi, foydalanuvchi_id, kurs_id, berilgan_sana, yakuniy_ball, daraja, tasdiqlash_kodi)
        VALUES (v_cert_id, NEW.foydalanuvchi_id, v_kurs_id, NOW(), NEW.foiz, v_daraja, v_verify_code);
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_test_passed ON public.test_urinishlari;
CREATE TRIGGER on_test_passed
  AFTER UPDATE OF muvaffaqiyatlimi ON public.test_urinishlari
  FOR EACH ROW WHEN (OLD.muvaffaqiyatlimi IS DISTINCT FROM NEW.muvaffaqiyatlimi AND NEW.muvaffaqiyatlimi = true)
  EXECUTE PROCEDURE public.check_and_issue_certificate();

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guruhlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foydalanuvchi_guruh ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kurslar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modullar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.darslar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dars_rasmlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foydalanuvchi_dars_progressi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.testlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_savollari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savol_variantlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_urinishlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_javoblari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sertifikatlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yangiliklar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xabarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xabar_oqish_holatlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bildirishnomalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tolovlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foydalanuvchi_kurs_ruxsatlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dars_jadvallari ENABLE ROW LEVEL SECURITY;

-- Asosiy Admin qoidasi (Barcha jadvallar uchun): Adminlar hamma narsani qila oladi.
-- Bu qoidani hamma jadvallarga tezkor beramiz:
DO $$ 
DECLARE
  t text;
BEGIN
  FOR t IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' LOOP
    EXECUTE format('CREATE POLICY "Admin_Full_Access" ON public.%I FOR ALL USING (public.get_my_role() = ''administrator'');', t);
  END LOOP;
END $$;

-- 5.1 Profiles (Foydalanuvchilar o'zini o'qishi va tahrirlashi mumkin)
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 5.2 O'quvchi ma'lumotlarni faqat o'qiy oladi (Kurslar, Modullar, Darslar)
CREATE POLICY "Public read kurslar" ON public.kurslar FOR SELECT USING (faolmi = true);
CREATE POLICY "Public read modullar" ON public.modullar FOR SELECT USING (faolmi = true);
CREATE POLICY "Public read darslar" ON public.darslar FOR SELECT USING (faolmi = true);
CREATE POLICY "Public read testlar" ON public.testlar FOR SELECT USING (faolmi = true);
CREATE POLICY "Public read savollar" ON public.test_savollari FOR SELECT USING (true);
CREATE POLICY "Public read variantlar" ON public.savol_variantlari FOR SELECT USING (true);

-- 5.3 O'zining progressini o'qish/yozish
CREATE POLICY "View own progress" ON public.foydalanuvchi_dars_progressi FOR SELECT USING (auth.uid() = foydalanuvchi_id);
CREATE POLICY "Update own progress" ON public.foydalanuvchi_dars_progressi FOR ALL USING (auth.uid() = foydalanuvchi_id);

CREATE POLICY "View own test history" ON public.test_urinishlari FOR SELECT USING (auth.uid() = foydalanuvchi_id);
-- Insert/Update to test_urinishlari is handled by SECURITY DEFINER function so RLS bypasses it automatically for creation.

-- 5.4 Sertifikatlarni tasdiqlash uchun ochiq o'qish (Mehmonlar uchun)
CREATE POLICY "Public can verify certificates" ON public.sertifikatlar FOR SELECT USING (bekor_qilinganmi = false);

-- 5.5 Xabarlar (Jo'natuvchi va Qabul qiluvchi o'qishi mumkin)
CREATE POLICY "View involved messages" ON public.xabarlar FOR SELECT USING (auth.uid() = yuboruvchi_id OR auth.uid() = qabul_qiluvchi_user_id);
CREATE POLICY "Teacher can send messages" ON public.xabarlar FOR INSERT WITH CHECK (public.get_my_role() = 'oqituvchi' AND auth.uid() = yuboruvchi_id);

-- 5.6 Bildirishnomalar
CREATE POLICY "View own notifications" ON public.bildirishnomalar FOR SELECT USING (auth.uid() = foydalanuvchi_id);
CREATE POLICY "Update own notifications" ON public.bildirishnomalar FOR UPDATE USING (auth.uid() = foydalanuvchi_id);
