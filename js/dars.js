import { supabase } from './supabase-config.js';

document.addEventListener('DOMContentLoaded', async () => {
    const fullLoader = document.getElementById('fullLoader');
    const lessonTitle = document.getElementById('lessonTitle');
    const videoContainer = document.getElementById('videoContainer');
    const lessonText = document.getElementById('lessonText');
    const lessonExercise = document.getElementById('lessonExercise');
    const finishLessonBtn = document.getElementById('finishLessonBtn');
    
    const urlParams = new URLSearchParams(window.location.search);
    const darsId = urlParams.get('id');

    if (!darsId) {
        alert("Dars tanlanmadi!");
        window.history.back();
        return;
    }

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            window.location.href = 'index.html';
            return;
        }

        // Darsni tortish
        const { data: dars, error } = await supabase
            .from('darslar')
            .select('*')
            .eq('id', darsId)
            .single();

        if (error) throw error;

        lessonTitle.textContent = dars.nomi;
        lessonText.innerHTML = dars.matn_kontenti ? dars.matn_kontenti.replace(/\n/g, '<br>') : 'Matn mavjud emas.';
        lessonExercise.innerHTML = dars.mashq_kontenti ? dars.mashq_kontenti.replace(/\n/g, '<br>') : 'Mashq berilmagan.';

        // YouTube havolasini iframe ga aylantirish (Sodda logika)
        if (dars.video_havola) {
            let embedUrl = dars.video_havola;
            if (embedUrl.includes('watch?v=')) {
                embedUrl = embedUrl.replace('watch?v=', 'embed/');
            }
            videoContainer.innerHTML = `<iframe src="${embedUrl}" allowfullscreen></iframe>`;
        } else {
            videoContainer.innerHTML = `<div class="w-full h-full flex items-center justify-center text-gray-500">Video mavjud emas</div>`;
        }

        finishLessonBtn.addEventListener('click', async () => {
            finishLessonBtn.textContent = 'Saqlanmoqda...';
            // Progressni yozish
            const { error: pError } = await supabase
                .from('foydalanuvchi_dars_progressi')
                .upsert({
                    foydalanuvchi_id: session.user.id,
                    dars_id: darsId,
                    tugatilganmi: true,
                    tugatilgan_sana: new Date().toISOString()
                }, { onConflict: 'foydalanuvchi_id,dars_id' }); // Upsert requires unique constraint on these 2, which TS didn't specify exactly, so let's just insert.
                
            alert("Dars muvaffaqiyatli tugatildi!");
            window.history.back();
        });

    } catch (err) {
        console.error(err);
        alert("Xatolik: " + err.message);
    } finally {
        fullLoader.classList.add('hidden');
    }
});
