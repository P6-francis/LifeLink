<?php
if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(16));
}
$notice = $_SESSION['report_notice'] ?? '';
unset($_SESSION['report_notice']);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['report_id'])) {
    $tokenOk = hash_equals($_SESSION['csrf'], (string) ($_POST['csrf'] ?? ''));
    $newStatus = ['ban' => 'Banned', 'dismiss' => 'Dismissed'][$_POST['action']] ?? null;

    if ($tokenOk && $newStatus !== null) {
        $allReports = lifelink_reports();
        foreach ($allReports as $report) {
            if ($report['id'] === $_POST['report_id']) {
                if ($newStatus === 'Banned' && !$report['banEligible']) {
                    $remaining = max(0, LIFELINK_BAN_REPORT_THRESHOLD - $report['uniqueReporterCount']);
                    $_SESSION['report_notice'] = 'Ban not available yet. ' . $remaining . ' more report(s) from different users are required.';
                    break;
                }
                if ($newStatus === 'Banned' && $report['reportedUserId'] !== '') {
                    foreach ($allReports as $relatedReport) {
                        if ($relatedReport['reportedUserId'] === $report['reportedUserId'] && $relatedReport['status'] === 'Pending') {
                            firestore_update($relatedReport['path'], ['status' => 'Banned']);
                        }
                    }
                    firestore_update('users/' . rawurlencode($report['reportedUserId']), [
                        'isBanned' => true,
                        'bannedAt' => gmdate('c'),
                        'bannedReason' => 'Account banned after reports from ' . $report['uniqueReporterCount'] . ' different users.',
                    ]);
                    $_SESSION['report_notice'] = 'User account banned after review of ' . $report['uniqueReporterCount'] . ' unique reporter(s).';
                } else {
                    firestore_update($report['path'], ['status' => $newStatus]);
                    $_SESSION['report_notice'] = 'Report dismissed.';
                }
                lifelink_cache_forget('reports');
                break;
            }
        }
    }

    header('Location: index.php?page=reports&p=' . max(1, (int) ($_POST['p'] ?? 1)));
    exit;
}

$sorted = lifelink_reports();

$pager = paginate($sorted, $_GET['p'] ?? 1);

$rows = [];
$popupIds = [];
$popups = '';

foreach ($pager['rows'] as $r) {
    $rows[] = [
        e($r['id']),
        e($r['name']),
        e($r['reporter']),
        '<strong>' . e($r['uniqueReporterCount']) . '</strong> unique',
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

        <div class="dialog-section">REPORTER INFORMATION</div>
        <div class="info-row"><span class="info-label">Name:</span><span class="info-value"><strong><?= e($r['reporter']) ?></strong></span></div>
        <div class="info-row"><span class="info-label">Email:</span><span class="info-value"><?= e($r['reporterEmail']) ?></span></div>
        <div class="info-row"><span class="info-label">Phone:</span><span class="info-value"><?= e($r['reporterPhone']) ?></span></div>
        <div class="info-row"><span class="info-label">Reports filed:</span><span class="info-value"><strong><?= e($r['reportsFiled']) ?></strong></span></div>
        <div class="dialog-divider"></div>

        <div class="dialog-section">REPORTED USER</div>
        <div class="info-row">
            <span class="info-label">Name:</span>
            <span class="info-value"><strong><?= e($r['name']) ?></strong></span>
        </div>
        <div class="info-row"><span class="info-label">Email:</span><span class="info-value"><?= e($r['reportedEmail']) ?></span></div>
        <div class="info-row"><span class="info-label">Phone:</span><span class="info-value"><?= e($r['reportedPhone']) ?></span></div>
        <div class="info-row"><span class="info-label">Unique reporters:</span><span class="info-value"><strong><?= e($r['uniqueReporterCount']) ?></strong> of <?= e(LIFELINK_BAN_REPORT_THRESHOLD) ?> required</span></div>
        <div class="info-row"><span class="info-label">Total reports:</span><span class="info-value"><strong><?= e($r['reportsReceived']) ?></strong></span></div>
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

            <?php if ($r['status'] === 'Pending' && $r['banEligible']): ?>
                <button type="submit" name="action" value="ban" class="action-btn ban-btn"
                        onclick="return confirm('This account was reported by <?= e($r['uniqueReporterCount']) ?> different users. Ban <?= e($r['name']) ?>?')">
                    <?= icon('gavel', 16) ?>
                    <span>Ban User</span>
                </button>
            <?php endif; ?>

            <?php if ($r['status'] === 'Pending'): ?>
                <button type="submit" name="action" value="dismiss" class="action-btn dismiss-btn">
                    <?= icon('cancel', 16) ?>
                    <span>Dismiss</span>
                </button>
            <?php endif; ?>

            <?php if ($r['status'] === 'Pending' && !$r['banEligible']): ?>
                <p class="moderation-note">Ban becomes available after <?= e(LIFELINK_BAN_REPORT_THRESHOLD) ?> different users report this account. <?= e(LIFELINK_BAN_REPORT_THRESHOLD - $r['uniqueReporterCount']) ?> more needed.</p>
            <?php elseif ($r['status'] === 'Banned'): ?>
                <p class="moderation-note moderation-note-success">This account has been banned.</p>
            <?php elseif ($r['status'] === 'Dismissed'): ?>
                <p class="moderation-note">This report was dismissed.</p>
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
    <?php if ($notice !== ''): ?>
        <p class="moderation-notice"><?= e($notice) ?></p>
    <?php endif; ?>
    <?= partial('table', [
        'columns' => ['REPORT ID', 'REPORTED USER', 'REPORTED BY', 'UNIQUE REPORTERS', 'REASON', 'STATUS', 'DATE'],
        'rows' => $rows,
        'popupIds' => $popupIds,
    ]) ?>
    <?= partial('pagination', ['pager' => $pager, 'noun' => 'reports']) ?>
    <?= $popups ?>
</section>
