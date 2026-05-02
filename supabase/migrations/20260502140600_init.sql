-- 1. ENUM'LAR YARATISH
CREATE TYPE user_role AS ENUM ('oquvchi', 'oqituvchi', 'administrator');
CREATE TYPE ui_theme AS ENUM ('light', 'dark', 'system');
CREATE TYPE ui_language AS ENUM ('uz', 'ru');
CREATE TYPE question_option_letter AS ENUM ('A', 'B', 'C', 'D');
CREATE TYPE certificate_grade AS ENUM ('alo', 'yaxshi', 'ortacha');
CREATE TYPE news_importance AS ENUM ('oddiy', 'muhim');
CREATE TYPE news_target_audience AS ENUM ('barchasi', 'faqat_oquvchilar', 'faqat_oqituvchilar');
CREATE TYPE message_target_type AS ENUM ('yakka_foydalanuvchi', 'butun_guruh');
CREATE TYPE notification_type AS ENUM ('yangi_dars', 'yangi_xabar', 'dars_eslatma', 'yangilik', 'sertifikat', 'tolov_tasdiqi');
CREATE TYPE payment_provider AS ENUM ('payme', 'click');
CREATE TYPE payment_status AS ENUM ('kutilmoqda', 'muvaffaqiyatli', 'bekor_qilingan', 'xato', 'qaytarilgan');

-- 2. FOYDALANUVCHILAR (Profiles)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    telefon TEXT,
    email TEXT,
    ism TEXT,
    avatar TEXT,
    rol user_role DEFAULT 'oquvchi',
    til ui_language DEFAULT 'uz',
    mavzu ui_theme DEFAULT 'system',
    ovozli_yoriqnoma BOOLEAN DEFAULT false,
    telefon_tasdiqlanganmi BOOLEAN DEFAULT false,
    oxirgi_faollik TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. GURUHLAR
CREATE TABLE guruhlar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nomi TEXT NOT NULL,
    tavsif TEXT,
    oqituvchi_id UUID REFERENCES profiles(id),
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. FOYDALANUVCHI-GURUH BOG'LANISHI
CREATE TABLE foydalanuvchi_guruh (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    guruh_id UUID REFERENCES guruhlar(id) ON DELETE CASCADE,
    qoshilgan_sana TIMESTAMPTZ DEFAULT NOW(),
    kim_qoshdi UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. KURSLAR
CREATE TABLE kurslar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nomi TEXT NOT NULL,
    tavsif TEXT,
    cover_rasm TEXT,
    tartib_raqami INT,
    narxi DECIMAL,
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. MODULLAR
CREATE TABLE modullar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kurs_id UUID REFERENCES kurslar(id) ON DELETE CASCADE,
    nomi TEXT NOT NULL,
    tavsif TEXT,
    cover_rasm TEXT,
    tartib_raqami INT,
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. DARSLAR
CREATE TABLE darslar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    modul_id UUID REFERENCES modullar(id) ON DELETE CASCADE,
    nomi TEXT NOT NULL,
    video_havola TEXT,
    matn_kontenti TEXT,
    mashq_kontenti TEXT,
    davomiyligi INT,
    tartib_raqami INT,
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. DARS RASMLARI
CREATE TABLE dars_rasmlari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dars_id UUID REFERENCES darslar(id) ON DELETE CASCADE,
    rasm TEXT,
    izoh TEXT,
    tartib_raqami INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. FOYDALANUVCHI DARS PROGRESSI
CREATE TABLE foydalanuvchi_dars_progressi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    dars_id UUID REFERENCES darslar(id) ON DELETE CASCADE,
    tugatilganmi BOOLEAN DEFAULT false,
    tugatilgan_sana TIMESTAMPTZ,
    video_soniya INT DEFAULT 0,
    oxirgi_tashrif TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. TESTLAR
CREATE TABLE testlar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    modul_id UUID REFERENCES modullar(id) ON DELETE CASCADE,
    kurs_id UUID REFERENCES kurslar(id) ON DELETE CASCADE,
    nomi TEXT NOT NULL,
    tavsif TEXT,
    vaqt_cheklovi INT,
    minimal_ball INT,
    kutish_vaqti INT,
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. TEST SAVOLLARI
CREATE TABLE test_savollari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID REFERENCES testlar(id) ON DELETE CASCADE,
    savol_matni TEXT NOT NULL,
    savol_rasmi TEXT,
    tartib_raqami INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. SAVOL VARIANTLARI
CREATE TABLE savol_variantlari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    savol_id UUID REFERENCES test_savollari(id) ON DELETE CASCADE,
    harf question_option_letter,
    variant_matni TEXT NOT NULL,
    togrimi BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. TEST URINISHLARI
CREATE TABLE test_urinishlari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    test_id UUID REFERENCES testlar(id) ON DELETE CASCADE,
    boshlangan_vaqt TIMESTAMPTZ,
    tugagan_vaqt TIMESTAMPTZ,
    togri_javoblar_soni INT,
    foiz DECIMAL,
    muvaffaqiyatlimi BOOLEAN,
    avtomatik_tugatildimi BOOLEAN,
    keyingi_urinish_vaqti TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. TEST JAVOBLARI
CREATE TABLE test_javoblari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    urinish_id UUID REFERENCES test_urinishlari(id) ON DELETE CASCADE,
    savol_id UUID REFERENCES test_savollari(id) ON DELETE CASCADE,
    tanlangan_variant_id UUID REFERENCES savol_variantlari(id) ON DELETE CASCADE,
    togrimi BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. SERTIFIKATLAR
CREATE TABLE sertifikatlar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sertifikat_id_kodi TEXT UNIQUE,
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    kurs_id UUID REFERENCES kurslar(id) ON DELETE CASCADE,
    berilgan_sana TIMESTAMPTZ,
    yakuniy_ball DECIMAL,
    daraja certificate_grade,
    tasdiqlash_kodi TEXT UNIQUE,
    bekor_qilinganmi BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. YANGILIKLAR
CREATE TABLE yangiliklar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sarlavha TEXT NOT NULL,
    matn TEXT,
    rasm TEXT,
    havola TEXT,
    faolmi BOOLEAN DEFAULT true,
    muhimligi news_importance DEFAULT 'oddiy',
    maqsadli_auditoriya news_target_audience DEFAULT 'barchasi',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. XABARLAR
CREATE TABLE xabarlar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    yuboruvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    qabul_qiluvchi_turi message_target_type,
    qabul_qiluvchi_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    qabul_qiluvchi_guruh_id UUID REFERENCES guruhlar(id) ON DELETE CASCADE,
    mavzu TEXT,
    matn TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18. XABAR O'QISH HOLATLARI
CREATE TABLE xabar_oqish_holatlari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    xabar_id UUID REFERENCES xabarlar(id) ON DELETE CASCADE,
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    oqilganmi BOOLEAN DEFAULT false,
    oqilgan_sana TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19. BILDIRISHNOMALAR
CREATE TABLE bildirishnomalar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    turi notification_type,
    sarlavha TEXT,
    matn TEXT,
    bogliq_id UUID,
    oqilganmi BOOLEAN DEFAULT false,
    push_yuborilganmi BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. TO'LOVLAR
CREATE TABLE tolovlar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    kurs_id UUID REFERENCES kurslar(id) ON DELETE CASCADE,
    summa DECIMAL,
    tolov_xizmati payment_provider,
    tashqi_tranzaksiya_id TEXT,
    holati payment_status,
    tasdiqlangan_sana TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21. FOYDALANUVCHI KURS RUXSATLARI
CREATE TABLE foydalanuvchi_kurs_ruxsatlari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    foydalanuvchi_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    kurs_id UUID REFERENCES kurslar(id) ON DELETE CASCADE,
    tolov_id UUID REFERENCES tolovlar(id) ON DELETE CASCADE,
    sotib_olingan_sana TIMESTAMPTZ,
    yaroqlilik_muddati TIMESTAMPTZ,
    faolmi BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 22. DARS JADVALLARI
CREATE TABLE dars_jadvallari (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guruh_id UUID REFERENCES guruhlar(id) ON DELETE CASCADE,
    mavzu TEXT,
    boshlanish_vaqti TIMESTAMPTZ,
    davomiyligi INT,
    tugatilganmi BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
