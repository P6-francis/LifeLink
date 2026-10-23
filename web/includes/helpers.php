<?php

const PAGE_SIZE = 5;

function e($value)
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

function icon($name, $size = null)
{
    $style = $size ? ' style="font-size:' . (int) $size . 'px"' : '';
    return '<span class="material-icons-round"' . $style . '>' . e($name) . '</span>';
}

function partial($name, array $vars = [])
{
    extract($vars, EXTR_SKIP);
    ob_start();
    include __DIR__ . '/../views/partials/' . $name . '.php';
    return ob_get_clean();
}

function pick($value, array $allowed)
{
    return in_array($value, $allowed, true) ? $value : $allowed[0];
}

function filter_rows(array $rows, $query, array $exact = [])
{
    $query = trim((string) $query);

    return array_values(array_filter($rows, function ($row) use ($query, $exact) {
        if ($query !== '' && mb_stripos($row['name'], $query) === false && mb_stripos($row['id'], $query) === false) {
            return false;
        }
        foreach ($exact as $field => $value) {
            if ($value !== 'All' && $row[$field] !== $value) {
                return false;
            }
        }
        return true;
    }));
}

function paginate(array $rows, $requested, $size = PAGE_SIZE)
{
    $total = count($rows);
    $pageCount = max(1, (int) ceil($total / $size));
    $page = min(max(1, (int) $requested), $pageCount);

    return [
        'rows' => array_slice($rows, ($page - 1) * $size, $size),
        'page' => $page,
        'pageCount' => $pageCount,
        'total' => $total,
        'size' => $size,
    ];
}

function page_items($page, $count)
{
    if ($count <= 5) {
        return range(1, $count);
    }

    $shown = array_unique(array_filter(
        [1, $count, $page - 1, $page, $page + 1],
        function ($p) use ($count) {
            return $p >= 1 && $p <= $count;
        }
    ));
    sort($shown);

    $items = [];
    foreach ($shown as $i => $p) {
        if ($i > 0 && $p - $shown[$i - 1] > 1) {
            $items[] = null;
        }
        $items[] = $p;
    }
    return $items;
}

function page_url($page)
{
    $params = $_GET;
    $params['p'] = $page;
    return '?' . http_build_query($params);
}

function column_flex($label)
{
    $l = strtoupper($label);
    if (str_contains($l, 'NAME')) return 1.8;
    if (str_contains($l, 'EMAIL')) return 2.4;
    if (str_contains($l, 'LOCATION')) return 1.8;
    if (str_contains($l, 'PHONE')) return 1.9;
    if (str_contains($l, 'DATE')) return 1.5;
    if (str_contains($l, 'STATUS')) return 1.4;
    if (str_contains($l, 'URGENCY')) return 1.3;
    if (str_contains($l, 'BAGS')) return 1.1;
    if ($l === 'BLOOD' || $l === 'TYPE' || $l === 'BLOOD TYPE') return 1.0;
    if (str_contains($l, 'ID')) return 1.3;
    return 1.5;
}

function blood_badge($type)
{
    return '<span class="badge-blood">' . e($type) . '</span>';
}

function status_badge($status)
{
    $tones = ['active' => 'info', 'fulfilled' => 'success', 'cancelled' => 'danger', 'pending' => 'warning', 'banned' => 'danger', 'dismissed' => 'neutral'];
    $tone = $tones[strtolower($status)] ?? 'neutral';
    return '<span class="badge-status tone-' . $tone . '"><i></i>' . e($status) . '</span>';
}

function urgency_badge($urgency)
{
    $tones = ['critical' => 'critical', 'urgent' => 'urgent'];
    $tone = $tones[strtolower($urgency)] ?? 'normal';
    return '<span class="badge-urgency urgency-' . $tone . '">' . e($urgency) . '</span>';
}

function unread_notifications()
{
    return count($_SESSION['read_notifications']) < count(NOTIFICATIONS);
}

function pie_slice_path($cx, $cy, $r, $start, $end)
{
    $x1 = $cx + $r * cos($start);
    $y1 = $cy + $r * sin($start);
    $x2 = $cx + $r * cos($end);
    $y2 = $cy + $r * sin($end);
    $large = ($end - $start) > M_PI ? 1 : 0;

    return sprintf('M%.3F %.3F L%.3F %.3F A%.3F %.3F 0 %d 1 %.3F %.3F Z', $cx, $cy, $x1, $y1, $r, $r, $large, $x2, $y2);
}

function find_by_id(array $rows, $id)
{
    foreach ($rows as $row) {
        if ($row['id'] === $id) {
            return $row;
        }
    }
    return null;
}
