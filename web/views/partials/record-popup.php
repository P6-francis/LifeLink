<template id="<?= e($id) ?>">
    <div class="dialog-head">
        <div class="dialog-title"><?= e($title) ?></div>
        <button class="dialog-close" type="button" data-dialog-close aria-label="Close"><?= icon('close', 16) ?></button>
    </div>
    <div class="dialog-subtitle"><?= e($subtitle) ?></div>
    <div class="dialog-divider"></div>
    <div class="dialog-section"><?= e($sectionLabel) ?></div>
    <?php if ($entry === null): ?>
        <div class="dialog-empty"><?= e($emptyText) ?></div>
    <?php else: ?>
        <div class="dialog-heading"><?= e($entry['heading']) ?></div>
        <?php foreach ($entry['fields'] as [$label, $value]): ?>
            <div class="info-row">
                <span class="info-label"><?= e($label) ?>:</span>
                <span class="info-value"><?= e($value) ?></span>
            </div>
        <?php endforeach; ?>
        <div class="info-row">
            <span class="info-label">Blood Type:</span>
            <?= blood_badge($entry['blood']) ?>
        </div>
        <div class="info-row">
            <span class="info-label">Blood Bags:</span>
            <span class="info-value"><?= e($entry['bags']) ?></span>
        </div>
        <div class="info-row">
            <span class="info-label">Status:</span>
            <?= status_badge($entry['status']) ?>
        </div>
    <?php endif; ?>
</template>
