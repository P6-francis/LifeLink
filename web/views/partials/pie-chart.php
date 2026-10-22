<?php
$colors = ['#C62828', '#1B6FC9', '#16835B', '#E59A00', '#7B4FC4', '#0FA3B1', '#E0589B', '#657083'];
arsort($data);
$labels = array_keys($data);
$values = array_values($data);
$total = array_sum($values);
$size = 130;
$center = $size / 2;
$angle = -M_PI / 2;
?>
<section class="panel pie-panel">
    <header class="panel-head">
        <div>
            <h2>Most Requested Blood Type</h2>
        </div>
    </header>
    <div class="pie-body">
        <div class="pie-row">
            <svg class="pie" width="<?= $size ?>" height="<?= $size ?>" viewBox="0 0 <?= $size ?> <?= $size ?>" aria-hidden="true">
                <?php foreach ($values as $i => $value):
                    $sweep = $value / $total * 2 * M_PI;
                    $path = pie_slice_path($center, $center, $center, $angle, $angle + $sweep);
                    $angle += $sweep;
                ?>
                    <path d="<?= $path ?>" fill="<?= $colors[$i % count($colors)] ?>" stroke="#fff" stroke-width="2"/>
                <?php endforeach; ?>
            </svg>
            <ul class="pie-legend">
                <?php foreach ($labels as $i => $label): ?>
                    <li<?= $i === 0 ? ' class="top"' : '' ?>>
                        <i style="background:<?= $colors[$i % count($colors)] ?>"></i>
                        <span><?= e($label) ?></span>
                        <em><?= number_format($values[$i] / $total * 100, 1) ?>%</em>
                    </li>
                <?php endforeach; ?>
            </ul>
        </div>
    </div>
</section>
