<?php
$query = trim($_GET['q'] ?? '');

$allRequests = lifelink_requests();
$blood = pick($_GET['blood'] ?? 'All', filter_options($allRequests, 'blood'));
$status = pick($_GET['status'] ?? 'All', filter_options($allRequests, 'status'));
$bags = pick($_GET['bags'] ?? 'All', filter_options($allRequests, 'bags'));
$filtered = filter_rows($allRequests, $query, ['blood' => $blood, 'status' => $status, 'bags' => $bags]);
$pager = paginate($filtered, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';
foreach ($pager['rows'] as $r) {
    $rows[] = [
        e($r['id']),
        e($r['name']),
        blood_badge($r['blood']),
        e($r['bags']),
        status_badge($r['status']),
        e($r['location']),
        e($r['date']),
    ];

    $donation = $r['donorId'] === '' ? null : ['id' => $r['id'], 'name' => $r['donorName'], 'location' => $r['location'], 'date' => $r['date'], 'blood' => $r['blood'], 'bags' => $r['bags'], 'status' => $r['status'] === 'Completed' ? 'Fulfilled' : $r['status']];
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
            'bags' => $donation['bags'],
            'status' => $donation['status'],
        ],
    ]);
}
?>
<?= partial('filters', [
    'route' => 'blood-requests',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Name, ID, blood type/bags, status, location, or date...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => filter_options($allRequests, 'blood'), 'value' => $blood],
        ['type' => 'select', 'name' => 'bags', 'label' => 'Blood Bags', 'options' => filter_options($allRequests, 'bags'), 'value' => $bags],
        ['type' => 'select', 'name' => 'status', 'label' => 'Status', 'options' => filter_options($allRequests, 'status'), 'value' => $status],
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
        'columns' => ['REQ ID', 'NAME', 'BLOOD TYPE', 'BLOOD BAGS', 'STATUS', 'LOCATION', 'REQUEST DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
    <?= $popups ?>
</section>
