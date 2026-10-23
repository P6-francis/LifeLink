<?php
$items = [
    'dashboard' => ['Dashboard', 'pie_chart'],
    'blood-requests' => ['Blood Request Records', 'water_drop'],
    'donations' => ['Donation Records', 'volunteer_activism'],
    'reports' => ['User Reports', 'report_problem'],
    'notifications' => ['Notifications', 'notifications'],
    'profile' => ['Profile', 'person'],
];
?>
<aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
        <img src="assets/images/lifelink_logo.png" alt="LifeLink">
        <div>
            <div class="brand-name">LifeLink</div>
            <div class="brand-tag">ADMIN CONSOLE</div>
        </div>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-label">MAIN MENU</div>
        <?php foreach ($items as $key => [$label, $iconName]): ?>
            <a class="nav-link<?= $key === $current ? ' active' : '' ?>" href="index.php?page=<?= e($key) ?>">
                <?= icon($iconName, 15) ?>
                <span><?= e($label) ?></span>
            </a>
        <?php endforeach; ?>
    </nav>

    <div class="sidebar-foot">
        <div class="profile">
            <div class="avatar avatar-lg">A</div>
            <div>
                <div class="profile-name"><?= e($_SESSION['admin_name'] ?? 'Administrator') ?></div>
                <div class="profile-role">Administrator</div>
            </div>
        </div>
        <a class="logout" href="admin-login.php?logout=1" data-logout-confirm>
            <?= icon('logout', 16) ?>
            <span>Logout</span>
        </a>
    </div>
</aside>
