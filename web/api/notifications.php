<?php

require __DIR__ . '/../includes/bootstrap.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$events = dashboard_report_notifications();
$ids = array_column($events, 'id');
$total = count($ids);
$read = $_SESSION['read_notifications'];
$action = $_POST['action'] ?? '';

if ($action === 'all') {
    $read = $ids;
} elseif ($action === 'toggle') {
    $id = trim((string) ($_POST['id'] ?? ''));
    if (in_array($id, $ids, true)) {
        $key = array_search($id, $read, true);
        if ($key === false) {
            $read[] = $id;
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
