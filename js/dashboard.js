import { supabase } from './supabase-config.js';

document.addEventListener('DOMContentLoaded', async () => {
    const fullLoader = document.getElementById('fullLoader');
    const errorBanner = document.getElementById('errorBanner');
    const errorText = document.getElementById('errorText');
    const userNameEl = document.getElementById('userName');
    const userAvatarEl = document.getElementById('userAvatar');
    const coursesContainer = document.getElementById('coursesContainer');
    const logoutBtn = document.getElementById('logoutBtn');

    function showError(msg) {
        errorText.textContent = msg;
        errorBanner.classList.remove('hidden');
        setTimeout(() => errorBanner.classList.add('hidden'), 5000);
    }

    try {
        // 1. Avtorizatsiyani tekshirish
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError || !session) {
            window.location.href = 'index.html'; // Tizimga kirmagan bo'lsa orqaga qaytarish
            return;
        }

        const user = session.user;

        // 2. Foydalanuvchi profilini tortish
        const { data: profileData, error: profileError } = await supabase
            .from('profiles')
            .select('ism, avatar, rol')
            .eq('id', user.id)
            .single();

        if (profileError && profileError.code !== 'PGRST116') {
            console.error(profileError);
            throw new Error("Profilni yuklab bo'lmadi.");
        }

        if (profileData) {
            const name = profileData.ism || 'O\'quvchi';
            userNameEl.textContent = name;
            userAvatarEl.textContent = name.charAt(0).toUpperCase();
            if(profileData.avatar) {
                userAvatarEl.innerHTML = `<img src="${profileData.avatar}" alt="Avatar" class="w-full h-full object-cover rounded-full">`;
            }
        }

        // 3. Aktiv kurslarni bazadan tortish
        const { data: coursesData, error: coursesError } = await supabase
            .from('kurslar')
            .select('*')
            .eq('faolmi', true)
            .order('tartib_raqami', { ascending: true });

        if (coursesError) {
            console.error(coursesError);
            throw new Error("Kurslarni yuklashda xatolik yuz berdi.");
        }

        // DOM ga chizish
        coursesContainer.innerHTML = ''; // Skeletons ni tozalash
        
        if (coursesData && coursesData.length > 0) {
            coursesData.forEach(course => {
                // Rasm yo'q bo'lsa chiroyli gradient placeholder
                const cover = course.cover_rasm || `https://ui-avatars.com/api/?name=${course.nomi}&background=eff6ff&color=2563eb&size=256&font-size=0.33`;
                const narx = course.narxi > 0 ? `${course.narxi.toLocaleString('uz-UZ')} so'm` : 'Bepul';
                
                const card = `
                    <div class="bg-white rounded-2xl p-3 shadow-[0_2px_10px_rgba(0,0,0,0.04)] border border-gray-100 hover:shadow-lg hover:border-blue-100 transition-all cursor-pointer flex flex-row space-x-4" onclick="alert('Kurs sahifasi hali yasalmadi!')">
                        <img src="${cover}" alt="${course.nomi}" class="w-28 h-28 object-cover rounded-xl bg-gray-50 border border-gray-100">
                        <div class="flex-1 flex flex-col justify-between py-1 pr-1">
                            <div>
                                <h4 class="font-bold text-gray-800 text-[15px] leading-tight">${course.nomi}</h4>
                                <p class="text-[12px] text-gray-500 mt-1 line-clamp-2">${course.tavsif || 'Kurs haqida qisqacha ma\'lumotlar va darslar ketma-ketligi.'}</p>
                            </div>
                            <div class="flex items-center justify-between mt-2">
                                <span class="text-blue-600 font-extrabold text-sm">${narx}</span>
                                <button class="bg-blue-50 text-blue-600 px-3 py-1.5 rounded-lg text-xs font-bold hover:bg-blue-100 transition">Boshlash</button>
                            </div>
                        </div>
                    </div>
                `;
                coursesContainer.insertAdjacentHTML('beforeend', card);
            });
        } else {
            coursesContainer.innerHTML = `
                <div class="text-center py-10 bg-white rounded-2xl border border-dashed border-gray-200">
                    <svg class="w-10 h-10 mx-auto text-gray-300 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path></svg>
                    <p class="text-gray-500 font-medium text-sm">Hozircha faol kurslar yo'q</p>
                </div>`;
        }

    } catch (err) {
        showError(err.message);
    } finally {
        // Ma'lumotlar tortib bo'lingach, Loaderni o'chiramiz
        fullLoader.style.opacity = '0';
        fullLoader.style.transition = 'opacity 0.3s ease';
        setTimeout(() => fullLoader.classList.add('hidden'), 300);
    }

    // Tizimdan chiqish (Logout)
    logoutBtn.addEventListener('click', async () => {
        if(confirm("Tizimdan chiqishni xohlaysizmi?")) {
            fullLoader.classList.remove('hidden');
            fullLoader.style.opacity = '1';
            const { error } = await supabase.auth.signOut();
            if (!error) {
                window.location.href = 'index.html';
            } else {
                fullLoader.classList.add('hidden');
                showError("Tizimdan chiqishda xatolik");
            }
        }
    });
});
