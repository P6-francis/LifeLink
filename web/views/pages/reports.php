<?php
if (!isset($_SESSION['reports']) || !is_array($_SESSION['reports'])) {
    $_SESSION['reports'] = REPORTS;
}
if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(16));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['report_id'])) {
    $tokenOk = hash_equals($_SESSION['csrf'], (string) ($_POST['csrf'] ?? ''));
    $newStatus = ['ban' => 'Banned', 'dismiss' => 'Dismissed'][$_POST['action']] ?? null;

    if ($tokenOk && $newStatus !== null) {
        foreach ($_SESSION['reports'] as &$report) {
            if ($report['id'] === $_POST['report_id']) {
                $report['status'] = $newStatus;
                break;
            }
        }
        unset($report);
    }

    header('Location: index.php?page=reports&p=' . max(1, (int) ($_POST['p'] ?? 1)));
    exit;
}

$sorted = $_SESSION['reports'];
usort($sorted, function ($a, $b) {
    return strcmp($b['id'], $a['id']);
});

$pager = paginate($sorted, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';

foreach ($pager['rows'] as $r) {
    $rows[] = [
        e($r['id']),
        e($r['name']),
        e($r['reporter']),
        e($r['reason']),
        status_badge($r['status']),
        e($r['date']),
    ];

    $popupIds[] = 'popup-' . $r['id'];

    ob_start();
    ?>
    <template id="popup-<?= e($r['id']) ?>">
        <div class="dialog-head">
            <div class="dialog-title">Report Details - <?= e($r['id']) ?></div>
            <button class="dialog-close" type="button" data-dialog-close aria-label="Close"><?= icon('close', 16) ?></button>
        </div>
        <div class="dialog-subtitle">Reported by <strong><?= e($r['reporter']) ?></strong></div>
        <div class="dialog-divider"></div>

        <div class="dialog-section">REPORTED USER</div>
        <div class="info-row">
            <span class="info-label">Name:</span>
            <span class="info-value"><strong><?= e($r['name']) ?></strong></span>
        </div>
        <div class="info-row">
            <span class="info-label">Reason:</span>
            <span class="info-value"><?= e($r['reason']) ?></span>
        </div>
        <div class="info-row">
            <span class="info-label">Location:</span>
            <span class="info-value"><?= e($r['location']) ?></span>
        </div>
        <div class="info-row">
            <span class="info-label">Date:</span>
            <span class="info-value"><?= e($r['date']) ?></span>
        </div>
        <div class="info-row">
            <span class="info-label">Status:</span>
            <?= status_badge($r['status']) ?>
        </div>

        <div class="dialog-divider"></div>
        <div class="dialog-section">INCIDENT REPORT</div>
        <p class="incident-text">"<?= e($r['description']) ?>"</p>

        <div class="dialog-divider"></div>
        <div class="dialog-section">ADMIN ACTION</div>
        <form class="moderation-actions" method="post" action="index.php?page=reports">
            <input type="hidden" name="csrf" value="<?= e($_SESSION['csrf']) ?>">
            <input type="hidden" name="report_id" value="<?= e($r['id']) ?>">
            <input type="hidden" name="p" value="<?= e($pager['page']) ?>">

            <?php if ($r['status'] !== 'Banned'): ?>
                <button type="submit" name="action" value="ban" class="action-btn ban-btn"
                        onclick="return confirm('Are you sure you want to ban <?= e($r['name']) ?>?')">
                    <?= icon('gavel', 16) ?>
                    <span>Ban User</span>
                </button>
            <?php endif; ?>

            <?php if ($r['status'] !== 'Dismissed'): ?>
                <button type="submit" name="action" value="dismiss" class="action-btn dismiss-btn">
                    <?= icon('cancel', 16) ?>
                    <span>Dismiss</span>
                </button>
            <?php endif; ?>
        </form>
    </template>
    <?php
    $popups .= ob_get_clean();
}
?>

<section class="panel" data-results>
    <header class="panel-head">
        <div>
            <h2>User Incident Reports</h2>
            <p>Review reason of reports.</p>
        </div>
    </header>
    <?= partial('table', [
        'columns' => ['REPORT ID', 'REPORTED USER', 'REPORTED BY', 'REASON', 'STATUS', 'DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'reports']) ?>
    <?= $popups ?>
</section>
