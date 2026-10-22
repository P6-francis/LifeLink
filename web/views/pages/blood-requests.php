<?php
$query = trim($_GET['q'] ?? '');
$blood = pick($_GET['blood'] ?? 'All', array_merge(['All'], BLOOD_TYPES));
$status = pick($_GET['status'] ?? 'All', ['All', 'Fulfilled', 'Cancelled']);

$filtered = filter_rows(BLOOD_REQUESTS, $query, ['blood' => $blood, 'status' => $status]);
$pager = paginate($filtered, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';
foreach ($pager['rows'] as $r) {
    $rows[] = [
        e($r['id']),
        e($r['name']),
        blood_badge($r['blood']),
        status_badge($r['status']),
        e($r['location']),
        e($r['date']),
    ];

    $donation = find_by_id(DONATIONS, $r['donationId']);
    $popupIds[] = 'popup-' . $r['id'];
    $popups .= partial('record-popup', [
        'id' => 'popup-' . $r['id'],
        'title' => $r['id'],
        'subtitle' => 'Requested by ' . $r['name'],
        'sectionLabel' => 'DONATED BY',
        'emptyText' => 'No donation has been made for this request yet.',
        'entry' => $donation === null ? null : [
            'heading' => $donation['name'],
            'fields' => [['Donation ID', $donation['id']], ['Location', $donation['location']], ['Date', $donation['date']]],
            'blood' => $donation['blood'],
            'status' => $donation['status'],
        ],
    ]);
}
?>
<?= partial('filters', [
    'route' => 'blood-requests',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Search by request ID or recipient name...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => array_merge(['All'], BLOOD_TYPES), 'value' => $blood],
        ['type' => 'select', 'name' => 'status', 'label' => 'Status', 'options' => ['All', 'Fulfilled', 'Cancelled'], 'value' => $status],
    ],
]) ?>

<section class="panel" data-results>
    <header class="panel-head">
        <div>
            <h2>Blood Request Records</h2>
            <p>Recent blood request transactions.</p>
        </div>
    </header>
    <?= partial('table', [
        'columns' => ['REQ ID', 'NAME', 'BLOOD TYPE', 'STATUS', 'LOCATION', 'REQUEST DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
    <?= $popups ?>
</section>
