<?php

// Repeated reports from a single account count once toward a ban.
const LIFELINK_BAN_REPORT_THRESHOLD = 3;

// Small server-session cache: avoids a new Firebase round trip every time the
// admin changes page or types in a filter, while keeping the dashboard fresh.
const LIFELINK_DASHBOARD_CACHE_SECONDS = 20;

function lifelink_cache_read(string $key): ?array {
    $entry = $_SESSION['lifelink_dashboard_cache'][$key] ?? null;
    if (!is_array($entry) || ($entry['expires'] ?? 0) < time() || !is_array($entry['data'] ?? null)) return null;
    return $entry['data'];
}

function lifelink_cache_write(string $key, array $data): void {
    $_SESSION['lifelink_dashboard_cache'][$key] = [
        'expires' => time() + LIFELINK_DASHBOARD_CACHE_SECONDS,
        'data' => $data,
    ];
}

function lifelink_cache_forget(string $key): void {
    unset($_SESSION['lifelink_dashboard_cache'][$key]);
}

function lifelink_date(mixed $timestamp): string {
    if (!is_string($timestamp) || $timestamp === '') return '-';
    try { return (new DateTimeImmutable($timestamp))->format('Y-m-d'); } catch (Throwable) { return '-'; }
}

function lifelink_requests(): array {
    if (($cached = lifelink_cache_read('requests')) !== null) return $cached;
    $rows = [];
    foreach (firestore_collection_group('requests') as $document) {
        $data = $document['data'];
        $rows[] = [
            'id' => $document['id'], 'path' => $document['path'],
            'name' => $data['requesterName'] ?? 'Requester', 'blood' => $data['bloodType'] ?? '-',
            'bags' => (int) ($data['bloodBagsNeeded'] ?? $data['bloodBags'] ?? 0),
            'status' => $data['status'] ?? 'Active', 'location' => $data['city'] ?? '-',
            'date' => lifelink_date($data['createdAt'] ?? null),
            'createdAt' => $data['createdAt'] ?? null, 'acceptedAt' => $data['acceptedAt'] ?? null,
            'completedAt' => $data['completedAt'] ?? null, 'ownerId' => $data['ownerId'] ?? '',
            'donorId' => $data['acceptedDonorId'] ?? '', 'donorName' => $data['acceptedDonorName'] ?? '',
        ];
    }
    usort($rows, static fn ($a, $b) => strcmp($b['date'], $a['date']));
    lifelink_cache_write('requests', $rows);
    return $rows;
}

function lifelink_donations(array $requests): array {
    $rows = [];
    foreach ($requests as $request) {
        if ($request['donorId'] === '') continue;
        $status = match ($request['status']) {
            'Completed' => 'Completed', 'Cancelled' => 'Cancelled', default => 'Accepted',
        };
        $donationTime = $request['completedAt'] ?? $request['acceptedAt'] ?? $request['createdAt'];
        $rows[] = [
            'id' => $request['id'], 'name' => $request['donorName'] ?: 'LifeLink donor',
            'blood' => $request['blood'], 'bags' => $request['bags'], 'status' => $status,
            'location' => $request['location'], 'date' => lifelink_date($donationTime),
            'requestId' => $request['id'],
        ];
    }
    return $rows;
}

function lifelink_reports(): array {
    if (($cached = lifelink_cache_read('reports')) !== null) return $cached;
    $documents = firestore_collection('userReports');
    $profileIds = [];
    foreach ($documents as $document) {
        foreach (['reporterId', 'reportedUserId'] as $field) {
            if (!empty($document['data'][$field])) $profileIds[$document['data'][$field]] = true;
        }
    }

    $profiles = [];
    foreach (array_keys($profileIds) as $userId) {
        $profile = firestore_document('users/' . rawurlencode($userId));
        $profiles[$userId] = $profile['data']['userInformation'] ?? [];
    }

    $receivedCounts = [];
    $filedCounts = [];
    $uniqueReporters = [];
    foreach ($documents as $document) {
        $data = $document['data'];
        $reportedId = $data['reportedUserId'] ?? '';
        $reporterId = $data['reporterId'] ?? '';
        if ($reportedId !== '') {
            $receivedCounts[$reportedId] = ($receivedCounts[$reportedId] ?? 0) + 1;
            if ($reporterId !== '') $uniqueReporters[$reportedId][$reporterId] = true;
        }
        if ($reporterId !== '') $filedCounts[$reporterId] = ($filedCounts[$reporterId] ?? 0) + 1;
    }

    $rows = [];
    foreach ($documents as $document) {
        $data = $document['data'];
        $reporterId = $data['reporterId'] ?? '';
        $reportedId = $data['reportedUserId'] ?? '';
        $reporter = $profiles[$reporterId] ?? [];
        $reported = $profiles[$reportedId] ?? [];
        $uniqueReporterCount = count($uniqueReporters[$reportedId] ?? []);
        $rows[] = [
            'id' => $document['id'], 'path' => $document['path'],
            'reporterId' => $reporterId, 'reportedUserId' => $reportedId,
            'reporter' => $reporter['fullName'] ?? $reporterId ?: 'LifeLink user',
            'reporterEmail' => $reporter['email'] ?? '-', 'reporterPhone' => $reporter['phone'] ?? '-',
            'name' => $data['reportedUserName'] ?? $reported['fullName'] ?? $reportedId ?: 'LifeLink user',
            'reportedEmail' => $reported['email'] ?? '-', 'reportedPhone' => $reported['phone'] ?? '-',
            'reportsReceived' => $receivedCounts[$reportedId] ?? 0,
            'uniqueReporterCount' => $uniqueReporterCount,
            'banEligible' => $uniqueReporterCount >= LIFELINK_BAN_REPORT_THRESHOLD,
            'reportsFiled' => $filedCounts[$reporterId] ?? 0,
            'reason' => $data['reason'] ?? 'Other', 'status' => $data['status'] ?? 'Pending',
            'location' => $data['location'] ?? '-', 'date' => lifelink_date($data['createdAt'] ?? null),
            'description' => $data['details'] ?? 'No description provided.',
        ];
    }
    usort($rows, static fn ($a, $b) => strcmp($b['date'], $a['date']));
    lifelink_cache_write('reports', $rows);
    return $rows;
}
