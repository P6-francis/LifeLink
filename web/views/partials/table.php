<?php
$flex = array_map('column_flex', $columns);
$totalFlex = array_sum($flex);
$minWidth = (int) round($totalFlex * 64 + 40 + 24 * (count($flex) - 1));
$popupIds = $popupIds ?? [];
$centered = array_map(function ($label) {
    return in_array(strtoupper($label), ['BLOOD BAGS', 'BLOOD TYPE'], true) ? ' class="is-center"' : '';
}, $columns);
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
                <?php foreach ($columns as $i => $label): ?>
                    <th<?= $centered[$i] ?>><?= e($label) ?></th>
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
                    <?php foreach ($row as $c => $cell): ?>
                        <td<?= $centered[$c] ?>><?= $cell ?></td>
                    <?php endforeach; ?>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
