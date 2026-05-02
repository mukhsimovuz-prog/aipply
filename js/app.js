import { supabase } from './supabase-config.js';

document.addEventListener('DOMContentLoaded', () => {
    
    // --- 1. KIRISH EKRANI (Login) ---
    const loginForm = document.getElementById('loginForm');
    if(loginForm) {
        // ... index.html dagi "Hisobingiz yo'qmi?" havolasi
        const linkHTML = `<div class="mt-6 text-center text-sm space-y-2 flex flex-col">
            <a href="parolni-tiklash.html" class="text-blue-600 font-medium hover:underline">Parolni unutdingizmi?</a>
            <span>Hisobingiz yo'qmi? <a href="royxatdan-otish.html" class="text-blue-600 font-semibold hover:underline">Ro'yxatdan o'ting</a></span>
        </div>`;
        if(!document.querySelector('a[href="royxatdan-otish.html"]')) {
            loginForm.insertAdjacentHTML('afterend', linkHTML);
        }

        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const errorMsg = document.getElementById('errorMsg');
            const btnText = document.getElementById('btnText');

            errorMsg.classList.add('hidden');
            btnText.textContent = "Kutilmoqda...";

            const { data, error } = await supabase.auth.signInWithPassword({ email, password });
            
            btnText.textContent = "Kirish";
            if (error) {
                errorMsg.textContent = "Xato: " + error.message;
                errorMsg.classList.remove('hidden');
            } else {
                alert("Muvaffaqiyatli kirdingiz!");
            }
        });
    }

    // --- 2. RO'YXATDAN O'TISH (Register) ---
    const registerForm = document.getElementById('registerForm');
    if(registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const ism = document.getElementById('regName').value;
            const email = document.getElementById('regEmail').value;
            const password = document.getElementById('regPassword').value;
            const errorMsg = document.getElementById('regErrorMsg');
            const successMsg = document.getElementById('regSuccessMsg');
            const btnText = document.getElementById('regBtnText');

            errorMsg.classList.add('hidden');
            successMsg.classList.add('hidden');
            btnText.textContent = "Yuklanmoqda...";

            // Supabase auth orqali ro'yxatdan o'tish (ism metadata ga yoziladi)
            const { data, error } = await supabase.auth.signUp({
                email: email,
                password: password,
                options: {
                    data: {
                        ism: ism
                    }
                }
            });

            btnText.textContent = "Ro'yxatdan o'tish";
            if (error) {
                errorMsg.textContent = "Xato: " + error.message;
                errorMsg.classList.remove('hidden');
            } else {
                successMsg.classList.remove('hidden');
                registerForm.reset();
            }
        });
    }

    // --- 3. PAROLNI TIKLASH (Reset) ---
    const resetForm = document.getElementById('resetForm');
    if(resetForm) {
        resetForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('resetEmail').value;
            const errorMsg = document.getElementById('resetErrorMsg');
            const successMsg = document.getElementById('resetSuccessMsg');
            
            errorMsg.classList.add('hidden');
            successMsg.classList.add('hidden');

            const { data, error } = await supabase.auth.resetPasswordForEmail(email);

            if (error) {
                errorMsg.textContent = "Xato: " + error.message;
                errorMsg.classList.remove('hidden');
            } else {
                successMsg.classList.remove('hidden');
                resetForm.reset();
            }
        });
    }
});
