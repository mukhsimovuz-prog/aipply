import { supabase } from './supabase-config.js';

document.addEventListener('DOMContentLoaded', async () => {
    const fullLoader = document.getElementById('fullLoader');
    const courseTitle = document.getElementById('courseTitle');
    const courseDesc = document.getElementById('courseDesc');
    const coursePrice = document.getElementById('coursePrice');
    const courseCover = document.getElementById('courseCover');
    const courseCoverPlaceholder = document.getElementById('courseCoverPlaceholder');
    const modulesContainer = document.getElementById('modulesContainer');
    const actionBtn = document.getElementById('actionBtn');
    
    const urlParams = new URLSearchParams(window.location.search);
    const kursId = urlParams.get('id');

    if (!kursId) {
        alert("Kurs tanlanmadi!");
        window.location.href = 'bosh-sahifa.html';
        return;
    }

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            window.location.href = 'index.html';
            return;
        }

        // 1. Kurs ma'lumotlarini tortish
        const { data: kurs, error: kursError } = await supabase
            .from('kurslar')
            .select('*')
            .eq('id', kursId)
            .single();

        if (kursError) throw kursError;

        courseTitle.textContent = kurs.nomi;
        courseDesc.textContent = kurs.tavsif || 'Tavsif kiritilmagan';
        coursePrice.textContent = kurs.narxi > 0 ? `${kurs.narxi.toLocaleString('uz-UZ')} UZS` : 'Bepul';
        
        if (kurs.cover_rasm) {
            courseCover.src = kurs.cover_rasm;
            courseCover.classList.remove('hidden');
            courseCoverPlaceholder.classList.add('hidden');
        }

        // 2. Modullar va Darslarni tortish
        const { data: modullar, error: modError } = await supabase
            .from('modullar')
            .select(`
                id, nomi, tartib_raqami,
                darslar ( id, nomi, davomiyligi, tartib_raqami )
            `)
            .eq('kurs_id', kursId)
            .eq('faolmi', true)
            .order('tartib_raqami', { ascending: true });

        if (modError) throw modError;

        if (modullar && modullar.length > 0) {
            modullar.forEach((modul, index) => {
                let darslarHTML = '';
                
                // Darslarni tartiblash
                const sortedDarslar = modul.darslar.sort((a, b) => a.tartib_raqami - b.tartib_raqami);
                
                sortedDarslar.forEach((dars, darsIndex) => {
                    const davomiylik = dars.davomiyligi ? `${dars.davomiyligi} daq` : '';
                    darslarHTML += `
                        <div onclick="window.location.href='dars.html?id=${dars.id}'" class="flex items-center justify-between p-3 hover:bg-blue-50 rounded-lg cursor-pointer transition border-b border-gray-50 last:border-0 group">
                            <div class="flex items-center space-x-3">
                                <div class="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xs group-hover:bg-blue-600 group-hover:text-white transition">
                                    ${darsIndex + 1}
                                </div>
                                <span class="text-sm font-medium text-gray-700 group-hover:text-blue-700">${dars.nomi}</span>
                            </div>
                            <div class="flex items-center text-xs text-gray-400">
                                ${davomiylik}
                                <svg class="w-4 h-4 ml-2 text-gray-300 group-hover:text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                            </div>
                        </div>
                    `;
                });

                const modulCard = `
                    <div class="bg-white border border-gray-100 rounded-xl overflow-hidden shadow-sm mb-4">
                        <div class="bg-gray-50 px-4 py-3 border-b border-gray-100 flex items-center justify-between">
                            <h4 class="font-bold text-gray-800 text-sm">${index + 1}. ${modul.nomi}</h4>
                            <span class="text-[10px] font-bold uppercase text-gray-400 bg-gray-200 px-2 py-0.5 rounded-full">${modul.darslar.length} ta dars</span>
                        </div>
                        <div class="p-1">
                            ${darslarHTML || '<p class="text-xs text-gray-400 p-3">Bu modulda hozircha darslar yo\'q</p>'}
                        </div>
                    </div>
                `;
                modulesContainer.insertAdjacentHTML('beforeend', modulCard);
            });
        } else {
            modulesContainer.innerHTML = `<p class="text-sm text-gray-500 bg-white p-4 rounded-xl border border-gray-100">Ushbu kursda hozircha modullar yo'q.</p>`;
        }

        // Action tugmasi mantig'i (sotib olish yoki davom ettirish)
        // Hozircha "To'lov qilinmagan", shuning uchun shunchaki "Darsni boshlash" deb birinchi darsga yo'naltiramiz.
        actionBtn.addEventListener('click', () => {
            if (modullar && modullar[0] && modullar[0].darslar[0]) {
                window.location.href = `dars.html?id=${modullar[0].darslar[0].id}`;
            } else {
                alert("Kursda darslar yo'q");
            }
        });

    } catch (err) {
        console.error(err);
        alert("Xatolik: " + err.message);
    } finally {
        fullLoader.classList.add('hidden');
    }
});
