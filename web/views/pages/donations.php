<?php
$query = trim($_GET['q'] ?? '');

$allRequests = lifelink_requests();
$allDonations = lifelink_donations($allRequests);
$blood = pick($_GET['blood'] ?? 'All', filter_options($allDonations, 'blood'));
$status = pick($_GET['status'] ?? 'All', filter_options($allDonations, 'status'));
$bags = pick($_GET['bags'] ?? 'All', filter_options($allDonations, 'bags'));
$filtered = filter_rows($allDonations, $query, ['blood' => $blood, 'status' => $status, 'bags' => $bags]);
$pager = paginate($filtered, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';
foreach ($pager['rows'] as $d) {
    $rows[] = [
        e($d['id']),
        e($d['name']),
        blood_badge($d['blood']),
        e($d['bags']),
        status_badge($d['status']),
        e($d['location']),
        e($d['date']),
    ];

    $request = find_by_id($allRequests, $d['requestId']);
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
            'bags' => $request['bags'],
            'status' => $request['status'],
        ],
    ]);
}
?>
<?= partial('filters', [
    'route' => 'donations',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Name, ID, blood type/bags, status, location, or date...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => filter_options($allDonations, 'blood'), 'value' => $blood],
        ['type' => 'select', 'name' => 'bags', 'label' => 'Blood Bags', 'options' => filter_options($allDonations, 'bags'), 'value' => $bags],
        ['type' => 'select', 'name' => 'status', 'label' => 'Status', 'options' => filter_options($allDonations, 'status'), 'value' => $status],
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
        'columns' => ['DON ID', 'NAME', 'BLOOD TYPE', 'BLOOD BAGS', 'STATUS', 'LOCATION', 'DONATION DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
    <?= $popups ?>
</section>
