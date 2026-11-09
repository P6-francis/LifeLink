<?php

$sessionPath = __DIR__ . '/../storage/sessions';

if (!is_dir($sessionPath)) {
    mkdir($sessionPath, 0775, true);
}

session_save_path($sessionPath);
session_set_cookie_params(['httponly' => true, 'samesite' => 'Lax', 'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off']);
session_start();

require __DIR__ . '/firebase.php';
require __DIR__ . '/live_data.php';
// Keeps UI option lists (such as blood types) available. Dashboard records are
// loaded from Firestore by live_data.php, not from the legacy sample arrays.
require __DIR__ . '/data.php';
require __DIR__ . '/helpers.php';

if (!isset($_SESSION['read_notifications']) || !is_array($_SESSION['read_notifications'])) {
    $_SESSION['read_notifications'] = [];
}
