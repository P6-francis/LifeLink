<?php
$query = trim($_GET['q'] ?? '');
$blood = pick($_GET['blood'] ?? 'All', array_merge(['All'], BLOOD_TYPES));
$status = pick($_GET['status'] ?? 'All', ['All', 'Fulfilled', 'Cancelled']);

$filtered = filter_rows(DONATIONS, $query, ['blood' => $blood, 'status' => $status]);
$pager = paginate($filtered, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';
foreach ($pager['rows'] as $d) {
    $rows[] = [
        e($d['id']),
        e($d['name']),
        blood_badge($d['blood']),
        status_badge($d['status']),
        e($d['location']),
        e($d['date']),
    ];

    $request = find_by_id(BLOOD_REQUESTS, $d['requestId']);
    $popupIds[] = 'popup-' . $d['id'];
    $popups .= partial('record-popup', [
        'id' => 'popup-' . $d['id'],
        'title' => $d['id'],
        'subtitle' => 'Donated by ' . $d['name'],
        'sectionLabel' => 'WENT TO REQUEST',
        'emptyText' => 'This donation is not linked to a request.',
        'entry' => $request === null ? null : [
            'heading' => $request['id'],
            'fields' => [['Recipient', $request['name']], ['Location', $request['location']], ['Date', $request['date']]],
            'blood' => $request['blood'],
            'status' => $request['status'],
        ],
    ]);
}
?>
<?= partial('filters', [
    'route' => 'donations',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Search by donation ID or donor name...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => array_merge(['All'], BLOOD_TYPES), 'value' => $blood],
        ['type' => 'select', 'name' => 'status', 'label' => 'Status', 'options' => ['All', 'Fulfilled', 'Cancelled'], 'value' => $status],
    ],
]) ?>

<section class="panel" data-results>
    <header class="panel-head">
        <div>
            <h2>Donation Records</h2>
            <p>Recent donation transactions.</p>
        </div>
    </header>
    <?= partial('table', [
        'columns' => ['DON ID', 'NAME', 'BLOOD TYPE', 'STATUS', 'LOCATION', 'DONATION DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
    <?= $popups ?>
</section>
