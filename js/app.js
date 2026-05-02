import { supabase } from './supabase-config.js';

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    if(loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const errorMsg = document.getElementById('errorMsg');
            const btnText = document.getElementById('btnText');
            const btnLoader = document.getElementById('btnLoader');

            // Reset UI
            errorMsg.classList.add('hidden');
            btnText.textContent = "Kutilmoqda...";
            btnLoader.classList.remove('hidden');

            const { data, error } = await supabase.auth.signInWithPassword({
                email: email,
                password: password,
            });

            btnText.textContent = "Kirish";
            btnLoader.classList.add('hidden');

            if (error) {
                errorMsg.textContent = "Xatolik: " + error.message;
                errorMsg.classList.remove('hidden');
            } else {
                alert("Muvaffaqiyatli kirdingiz!");
            }
        });
    }
});
