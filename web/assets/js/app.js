(function () {
    var body = document.body;

    function setDrawer(open) {
        body.classList.toggle('drawer-open', open);
    }

    document.addEventListener('click', function (event) {
        if (event.target.closest('[data-menu-toggle]')) {
            setDrawer(!body.classList.contains('drawer-open'));
        } else if (event.target.closest('[data-scrim]')) {
            setDrawer(false);
        }
    });

    var dialog = document.querySelector('[data-dialog]');
    var dialogBody = document.querySelector('[data-dialog-body]');

    function openDialog(templateId) {
        var template = document.getElementById(templateId);
        if (!template) {
            return;
        }
        dialogBody.textContent = '';
        dialogBody.appendChild(template.content.cloneNode(true));
        dialog.hidden = false;
    }

    function closeDialog() {
        dialog.hidden = true;
        dialogBody.textContent = '';
    }

    document.addEventListener('click', function (event) {
        if (event.target.closest('[data-logout-confirm]')) {
            event.preventDefault();
            openDialog('logout-confirmation');
        }
    });

    document.addEventListener('click', function (event) {
        var row = event.target.closest('tr[data-popup]');
        if (row) {
            openDialog(row.dataset.popup);
        } else if (event.target === dialog || event.target.closest('[data-dialog-close]')) {
            closeDialog();
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            setDrawer(false);
            closeDialog();
        }
    });

    window.addEventListener('resize', function () {
        if (window.innerWidth >= 900) {
            setDrawer(false);
        }
    });

    var filterForm = document.querySelector('[data-filter-form]');
    var requestId = 0;
    var typingTimer = null;

    function loadResults(url) {
        var current = document.querySelector('[data-results]');
        if (!current) {
            window.location.href = url;
            return;
        }

        var id = ++requestId;

        fetch(url, { headers: { 'X-Requested-With': 'fetch' } })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error('Request failed');
                }
                return response.text();
            })
            .then(function (html) {
                if (id !== requestId) {
                    return;
                }
                var doc = new DOMParser().parseFromString(html, 'text/html');
                var next = doc.querySelector('[data-results]');
                if (!next) {
                    window.location.href = url;
                    return;
                }
                current.innerHTML = next.innerHTML;
                window.history.replaceState(null, '', url);
            })
            .catch(function () {
                window.location.href = url;
            });
    }

    function currentFilterUrl() {
        var params = new URLSearchParams(new FormData(filterForm));
        return window.location.pathname + '?' + params.toString();
    }

    if (filterForm) {
        filterForm.addEventListener('submit', function (event) {
            event.preventDefault();
            clearTimeout(typingTimer);
            loadResults(currentFilterUrl());
        });

        filterForm.addEventListener('change', function (event) {
            if (event.target.tagName === 'SELECT') {
                loadResults(currentFilterUrl());
            }
        });

        filterForm.addEventListener('input', function (event) {
            if (event.target.type === 'text') {
                clearTimeout(typingTimer);
                typingTimer = setTimeout(function () {
                    loadResults(currentFilterUrl());
                }, 250);
            }
        });
    }

    document.addEventListener('click', function (event) {
        var link = event.target.closest('[data-results] a.page-btn');
        if (!link) {
            return;
        }
        event.preventDefault();
        loadResults(link.href);
    });

    function applyReadState(read, total) {
        document.querySelectorAll('[data-notification]').forEach(function (row) {
            var isRead = read.indexOf(Number(row.dataset.index)) !== -1;
            row.classList.toggle('is-read', isRead);
            var button = row.querySelector('[data-toggle-read]');
            if (button) {
                button.title = isRead ? 'Mark as unread' : 'Mark as read';
            }
        });

        var allRead = read.length >= total;

        var markAll = document.querySelector('[data-mark-all]');
        if (markAll) {
            markAll.disabled = allRead;
        }

        var dot = document.querySelector('[data-unread-dot]');
        if (dot) {
            dot.hidden = allRead;
        }
    }

    function sendNotificationAction(data) {
        fetch('api/notifications.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(data).toString()
        })
            .then(function (response) {
                return response.json();
            })
            .then(function (result) {
                if (result && Array.isArray(result.read)) {
                    applyReadState(result.read, result.total);
                }
            });
    }

    document.addEventListener('click', function (event) {
        var toggle = event.target.closest('[data-toggle-read]');
        if (toggle) {
            var row = toggle.closest('[data-notification]');
            sendNotificationAction({ action: 'toggle', index: row.dataset.index });
            return;
        }

        var markAll = event.target.closest('[data-mark-all]');
        if (markAll && !markAll.disabled) {
            sendNotificationAction({ action: 'all' });
        }
    });
})();
