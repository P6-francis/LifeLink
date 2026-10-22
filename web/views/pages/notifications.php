<?php
$read = $_SESSION['read_notifications'];
$allRead = count($read) >= count(NOTIFICATIONS);
?>
<div class="notif-actions">
    <button class="btn-outline" type="button" data-mark-all<?= $allRead ? ' disabled' : '' ?>>
        <?= icon('check', 14) ?>
        <span>Mark all read</span>
    </button>
</div>

<div class="panel notif-list" data-notification-list data-total="<?= count(NOTIFICATIONS) ?>">
    <?php foreach (NOTIFICATIONS as $i => $item):
        $isRead = in_array($i, $read, true);
    ?>
        <div class="notif-row tone-<?= e($item['tone']) ?><?= $isRead ? ' is-read' : '' ?>" data-notification data-index="<?= $i ?>">
            <div class="notif-icon"><?= icon('notifications', 13) ?></div>
            <div class="notif-text">
                <div class="notif-title"><?= e($item['title']) ?></div>
                <div class="notif-body"><?= e($item['body']) ?></div>
                <div class="notif-time"><?= e($item['time']) ?></div>
            </div>
            <button class="icon-btn notif-check" type="button" data-toggle-read
                    title="<?= $isRead ? 'Mark as unread' : 'Mark as read' ?>">
                <?= icon('check', 16) ?>
            </button>
        </div>
    <?php endforeach; ?>
</div>
