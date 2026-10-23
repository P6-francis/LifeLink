<div class="profile-wrap">
    <div class="profile-layout">
        <section class="panel">
            <header class="panel-head">
                <div>
                    <h2>Profile Information</h2>
                    <p>Update your basic account details.</p>
                </div>
            </header>
            <div class="form-grid three">
                <div class="form-field">
                    <label class="filter-label" for="p-first">First Name</label>
                    <input class="form-input" type="text" id="p-first" placeholder="Enter first name" autocomplete="off">
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-last">Last Name</label>
                    <input class="form-input" type="text" id="p-last" placeholder="Enter last name" autocomplete="off">
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-user">Username</label>
                    <input class="form-input" type="text" id="p-user" placeholder="Enter username" autocomplete="off">
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-email">Email</label>
                    <input class="form-input" type="text" id="p-email" placeholder="Enter email address" autocomplete="off">
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-phone">Phone Number</label>
                    <input class="form-input" type="tel" id="p-phone" placeholder="Enter phone number" autocomplete="off">
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-address">Address</label>
                    <input class="form-input" type="text" id="p-address" placeholder="Enter address" autocomplete="off">
                </div>
            </div>
            <div class="form-actions">
                <button class="btn-primary" type="button">Save Changes</button>
            </div>
        </section>

        <section class="panel">
            <header class="panel-head">
                <div>
                    <h2>Reset Password</h2>
                    <p>Choose a new password for your account.</p>
                </div>
            </header>
            <div class="form-grid three">
                <div class="form-field">
                    <label class="filter-label" for="p-current">Current Password</label>
                    <div class="password-wrap">
                        <input class="form-input" type="password" id="p-current" placeholder="Enter current password" autocomplete="current-password">
                        <button type="button" class="toggle-password" data-toggle-password="p-current" aria-label="show password">
                            <span class="material-icons-round slashed">visibility_off</span>
                        </button>
                    </div>
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-new">New Password</label>
                    <div class="password-wrap">
                        <input class="form-input" type="password" id="p-new" placeholder="Enter new password" autocomplete="new-password">
                        <button type="button" class="toggle-password" data-toggle-password="p-new" aria-label="show password">
                            <span class="material-icons-round slashed">visibility_off</span>
                        </button>
                    </div>
                </div>
                <div class="form-field">
                    <label class="filter-label" for="p-confirm">Confirm Password</label>
                    <div class="password-wrap">
                        <input class="form-input" type="password" id="p-confirm" placeholder="Confirm new password" autocomplete="new-password">
                        <button type="button" class="toggle-password" data-toggle-password="p-confirm" aria-label="show password">
                            <span class="material-icons-round slashed">visibility_off</span>
                        </button>
                    </div>
                </div>
            </div>
            <div class="form-actions">
                <button class="btn-primary" type="button">Reset Password</button>
            </div>
        </section>
    </div>
</div>

<script>
    document.querySelectorAll('[data-toggle-password]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            const input = document.getElementById(btn.dataset.togglePassword);
            const icon = btn.querySelector('.material-icons-round');
            const show = input.type === 'password';

            input.type = show ? 'text' : 'password';
            icon.textContent = show ? 'visibility' : 'visibility_off';
            icon.classList.toggle('slashed', !show);
            btn.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
        });
    });
</script>
