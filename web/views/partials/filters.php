<form class="filter-panel" method="get" action="index.php" data-filter-form>
    <input type="hidden" name="page" value="<?= e($route) ?>">
    <div class="filter-fields">
        <?php foreach ($fields as $field): ?>
            <?php if ($field['type'] === 'search'): ?>
                <div class="filter-field search">
                    <label class="filter-label" for="f-<?= e($field['name']) ?>"><?= e($field['label']) ?></label>
                    <div class="search-box">
                        <?= icon('search', 15) ?>
                        <input type="text" id="f-<?= e($field['name']) ?>" name="<?= e($field['name']) ?>"
                               value="<?= e($field['value']) ?>" placeholder="<?= e($field['hint']) ?>" autocomplete="off">
                    </div>
                </div>
            <?php else: ?>
                <div class="filter-field select">
                    <label class="filter-label" for="f-<?= e($field['name']) ?>"><?= e($field['label']) ?></label>
                    <div class="select-box">
                        <select id="f-<?= e($field['name']) ?>" name="<?= e($field['name']) ?>">
                            <?php foreach ($field['options'] as $option): ?>
                                <option value="<?= e($option) ?>"<?= $option === $field['value'] ? ' selected' : '' ?>><?= e($option) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <?= icon('keyboard_arrow_down', 16) ?>
                    </div>
                </div>
            <?php endif; ?>
        <?php endforeach; ?>
    </div>
</form>
