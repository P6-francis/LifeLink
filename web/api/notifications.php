<?php

require __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$total = count(NOTIFICATIONS);
$read = $_SESSION['read_notifications'];
$action = $_POST['action'] ?? '';

if ($action === 'all') {
    $read = range(0, $total - 1);
} elseif ($action === 'toggle') {
    $index = filter_input(INPUT_POST, 'index', FILTER_VALIDATE_INT);
    if ($index !== null && $index !== false && $index >= 0 && $index < $total) {
        $key = array_search($index, $read, true);
        if ($key === false) {
            $read[] = $index;
        } else {
            unset($read[$key]);
        }
    }
}

$_SESSION['read_notifications'] = array_values($read);

echo json_encode([
    'read' => $_SESSION['read_notifications'],
    'total' => $total,
]);
