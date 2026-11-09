<?php

require __DIR__ . '/includes/bootstrap.php';

if (empty($_SESSION['admin_authenticated'])) {
    header('Location: admin-login.php');
    exit;
}

$pages = [
    'dashboard' => [
        'title' => 'Dashboard Overview',
        'subtitle' => 'Monitor blood donations, users, and active requests.',
    ],
    'blood-requests' => [
        'title' => 'Blood Request Records',
        'subtitle' => 'Track and review blood request activity.',
    ],
    'donations' => [
        'title' => 'Donation Records',
        'subtitle' => 'Track and review blood donation activity.',
    ],
    'reports' => [
        'title' => 'User Reports',
        'subtitle' => 'Manage and review user reports.',
    ],
    'notifications' => [
        'title' => 'Notifications',
        'subtitle' => 'Recent activity and system alerts.',
    ],
    'profile' => [
        'title' => 'Profile',
        'subtitle' => 'Manage your account information and password.',
    ],
];

$current = $_GET['page'] ?? 'dashboard';
if (!isset($pages[$current])) {
    $current = 'dashboard';
}
$meta = $pages[$current];

ob_start();
try {
    require __DIR__ . '/views/pages/' . $current . '.php';
    $content = ob_get_clean();
} catch (Throwable $exception) {
    ob_end_clean();
    error_log('LifeLink Firebase dashboard error: ' . $exception->getMessage());
    $isLocal = in_array($_SERVER['HTTP_HOST'] ?? '', ['lifelink-admin.local', 'lifelink-admin.local:80', 'localhost', 'localhost:80'], true);
    $detail = $isLocal ? '<p><strong>Local diagnostic:</strong> ' . e($exception->getMessage()) . '</p>' : '';
    $content = '<section class="panel"><header class="panel-head"><div><h2>Firebase connection needs configuration</h2><p>Set the server environment variables from web/.env.example, then reload the dashboard.</p>' . $detail . '</div></header></section>';
}

require __DIR__ . '/views/layout.php';
