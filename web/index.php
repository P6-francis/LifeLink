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
    'notifications' => [
        'title' => 'Notifications',
        'subtitle' => 'Recent activity and system alerts.',
    ],
];

$current = $_GET['page'] ?? 'dashboard';
if (!isset($pages[$current])) {
    $current = 'dashboard';
}
$meta = $pages[$current];

ob_start();
require __DIR__ . '/views/pages/' . $current . '.php';
$content = ob_get_clean();

require __DIR__ . '/views/layout.php';
