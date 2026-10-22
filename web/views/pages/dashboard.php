<?php
$query = trim($_GET['q'] ?? '');
$blood = pick($_GET['blood'] ?? 'All', array_merge(['All'], BLOOD_TYPES));
$urgency = pick($_GET['urgency'] ?? 'All', ['All', 'CRITICAL', 'URGENT', 'NORMAL']);

$filtered = filter_rows(DASHBOARD_REQUESTS, $query, ['blood' => $blood, 'urgency' => $urgency]);
$pager = paginate($filtered, $_GET['p'] ?? 1);

$rows = [];
foreach ($pager['rows'] as $r) {
    $rows[] = [
        e($r['id']),
        e($r['name']),
        blood_badge($r['blood']),
        urgency_badge($r['urgency']),
        status_badge($r['status']),
        e($r['location']),
        e($r['date']),
    ];
}
?>
<div class="stats-wrap">
    <div class="stats-grid">
        <div class="stat-cards">
            <?= partial('stat-card', ['title' => 'Total Users', 'value' => '2179', 'iconName' => 'people_alt']) ?>
            <?= partial('stat-card', ['title' => 'Donations This Month', 'value' => '141', 'iconName' => 'calendar_month']) ?>
            <?= partial('stat-card', ['title' => 'Active Requests', 'value' => '79', 'iconName' => 'water_drop']) ?>
            <?= partial('stat-card', ['title' => 'Donations This Week', 'value' => '34', 'iconName' => 'calendar_month']) ?>
        </div>
        <?= partial('pie-chart', ['data' => REQUESTS_BY_BLOOD_TYPE]) ?>
    </div>
</div>

<?= partial('filters', [
    'route' => 'dashboard',
    'fields' => [
        ['type' => 'search', 'name' => 'q', 'label' => 'Search', 'hint' => 'Search by active ID or recipient name...', 'value' => $query],
        ['type' => 'select', 'name' => 'blood', 'label' => 'Blood Type', 'options' => array_merge(['All'], BLOOD_TYPES), 'value' => $blood],
        ['type' => 'select', 'name' => 'urgency', 'label' => 'Urgency', 'options' => ['All', 'CRITICAL', 'URGENT', 'NORMAL'], 'value' => $urgency],
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
        'columns' => ['ACT ID', 'NAME', 'BLOOD TYPE', 'URGENCY', 'STATUS', 'LOCATION', 'REQUEST DATE'],
        'rows' => $rows,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'results']) ?>
</section>
