<?php
$flex = array_map('column_flex', $columns);
$totalFlex = array_sum($flex);
$minWidth = (int) round($totalFlex * 92 + 40 + 24 * (count($flex) - 1));
$popupIds = $popupIds ?? [];
?>
<div class="table-scroll">
    <table class="data-table" style="min-width:<?= $minWidth ?>px">
        <colgroup>
            <?php foreach ($flex as $f): ?>
                <col style="width:<?= round($f / $totalFlex * 100, 3) ?>%">
            <?php endforeach; ?>
        </colgroup>
        <thead>
            <tr>
                <?php foreach ($columns as $label): ?>
                    <th><?= e($label) ?></th>
                <?php endforeach; ?>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($rows as $i => $row): ?>
                <?php if (isset($popupIds[$i])): ?>
                    <tr class="is-clickable" data-popup="<?= e($popupIds[$i]) ?>">
                <?php else: ?>
                    <tr>
                <?php endif; ?>
                    <?php foreach ($row as $cell): ?>
                        <td><?= $cell ?></td>
                    <?php endforeach; ?>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
