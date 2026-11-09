<?php
$events = dashboard_report_notifications();
$read = $_SESSION['read_notifications'];
$allRead = dashboard_unread_notification_count($events) === 0;
?>
<div class="notif-actions"><button class="btn-outline" type="button" data-mark-all<?= $allRead ? ' disabled' : '' ?>><?= icon('check', 14) ?><span>Mark all read</span></button></div>
<div class="panel notif-list">
    <?php if ($events === []): ?>
        <div class="notif-row is-read"><div class="notif-icon"><?= icon('notifications_none', 13) ?></div><div class="notif-text"><div class="notif-title">No ban reviews waiting</div><div class="notif-body">An alert appears here when an account reaches the report-review threshold.</div></div></div>
    <?php endif; ?>
    <?php foreach ($events as $item): ?>
        <?php $isRead = in_array($item['id'], $read, true); ?>
        <div class="notif-row tone-<?= e($item['tone']) ?><?= $isRead ? ' is-read' : '' ?>" data-notification data-id="<?= e($item['id']) ?>"><div class="notif-icon"><?= icon('report_problem', 13) ?></div><div class="notif-text"><div class="notif-title"><?= e($item['title']) ?></div><div class="notif-body"><?= e($item['body']) ?></div><div class="notif-time"><?= e($item['time']) ?></div><a class="notif-review-link" href="<?= e($item['reviewUrl']) ?>">Review and decide</a></div><button class="icon-btn notif-check" type="button" data-toggle-read title="<?= $isRead ? 'Mark as unread' : 'Mark as read' ?>"><?= icon('check', 16) ?></button></div>
    <?php endforeach; ?>
</div>
