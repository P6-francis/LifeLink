<?php

$sessionPath = __DIR__ . '/../storage/sessions';

if (!is_dir($sessionPath)) {
    mkdir($sessionPath, 0775, true);
}

session_save_path($sessionPath);
session_start();
//account ni admin
const ADMIN_EMAIL = 'admin@lifelink.com';
const ADMIN_PASSWORD = 'admin123';

require __DIR__ . '/data.php';
require __DIR__ . '/helpers.php';

if (!isset($_SESSION['read_notifications']) || !is_array($_SESSION['read_notifications'])) {
    $_SESSION['read_notifications'] = [];
}
