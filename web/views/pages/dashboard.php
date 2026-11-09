<?php
$query = trim($_GET['q'] ?? '');

$allRequests = lifelink_requests();
$activeRequests = array_values(array_filter($allRequests, static fn ($request) => $request['status'] === 'Active'));
$blood = pick($_GET['blood'] ?? 'All', filter_options($activeRequests, 'blood'));
$bags = pick($_GET['bags'] ?? 'All', filter_options($activeRequests, 'bags'));
$filtered = filter_rows($activeRequests, $query, ['blood' => $blood, 'bags' => $bags]);
$pager = paginate($filtered, $_GET['p'] ?? 1);
$userCount = count(firestore_collection('users'));
$donations = lifelink_donations($allRequests);
$thisMonth = date('Y-m');
$monthDonations = count(array_filter($donations, static fn ($donation) => str_starts_with($donation['date'], $thisMonth)));
$requestsByBloodType = array_fill_keys(BLOOD_TYPES, 0);
foreach ($allRequests as $request) if (isset($requestsByBloodType[$request['blood']])) $requestsByBloodType[$request['blood']]++;

$rows = [];
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
}
?>
<div class="stats-wrap">
    <div class="stats-grid">
        <div class="stat-cards">
            <?= partial('stat-card', ['title' => 'Total Users', 'value' => (string) $userCount, 'iconName' => 'people_alt']) ?>
            <?= partial('stat-card', ['title' => 'Donations This Month', 'value' => (string) $monthDonations, 'iconName' => 'calendar_month']) ?>
            <?= partial('stat-card', ['title' => 'Active Requests', 'value' => (string) count($activeRequests), 'iconName' => 'water_drop']) ?>
            <?= partial('stat-card', ['title' => 'Total Donations', 'value' => (string) count($donations), 'iconName' => 'calendar_month']) ?>
        </div>
        <?= partial('pie-chart', ['data' => $requestsByBloodType]) ?>
    </div>
</div>

<?= partial('filters', [
    'route' => 'dashboard',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Name, ID, blood type/bags, status, location, or date...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => filter_options($activeRequests, 'blood'), 'value' => $blood],
        ['type' => 'select', 'name' => 'bags', 'label' => 'Blood Bags', 'options' => filter_options($activeRequests, 'bags'), 'value' => $bags],
    ],
]) ?>

<section class="panel" data-results>
    <header class="panel-head">
        <div>
            <h2>Active Blood Requests</h2>
            <p>Latest active requests requiring attention.</p>
        </div>
    </header>
    <?= partial('table', [
        'columns' => ['ACT ID', 'NAME', 'BLOOD TYPE', 'BLOOD BAGS', 'STATUS', 'LOCATION', 'REQUEST DATE'],
        'rows' => $rows,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
</section>
