<?php
$page = $pager['page'];
$pageCount = $pager['pageCount'];
$total = $pager['total'];
$start = $total === 0 ? 0 : ($page - 1) * $pager['size'] + 1;
$end = min($page * $pager['size'], $total);
$label = $total === 0 ? 'No results found' : "Showing $start-$end of $total $noun";
?>
<footer class="pagination">
    <span class="pagination-label"><?= e($label) ?></span>
    <nav class="pager" aria-label="Pagination">
        <?php if ($page > 1): ?>
            <a class="page-btn" href="<?= e(page_url($page - 1)) ?>" aria-label="Previous page"><?= icon('chevron_left', 12) ?></a>
        <?php else: ?>
            <span class="page-btn is-disabled"><?= icon('chevron_left', 12) ?></span>
        <?php endif; ?>

        <?php foreach (page_items($page, $pageCount) as $item): ?>
            <?php if ($item === null): ?>
                <span class="page-gap">...</span>
            <?php else: ?>
                <a class="page-btn<?= $item === $page ? ' active' : '' ?>" href="<?= e(page_url($item)) ?>"><?= $item ?></a>
            <?php endif; ?>
        <?php endforeach; ?>

        <?php if ($page < $pageCount): ?>
            <a class="page-btn" href="<?= e(page_url($page + 1)) ?>" aria-label="Next page"><?= icon('chevron_right', 12) ?></a>
        <?php else: ?>
            <span class="page-btn is-disabled"><?= icon('chevron_right', 12) ?></span>
        <?php endif; ?>
    </nav>
</footer>
