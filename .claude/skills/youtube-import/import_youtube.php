<?php
/*
 * Imports a YouTube batch (made by make_visuals.py) into the myBonus backend.
 *
 * Usage: php import_youtube.php <laravel_root> <bundle_dir> [--dry-run]
 *   bundle_dir holds batch.json plus the generated jpgs.
 *
 * Idempotent: a category/series is matched by name/title, a video by its
 * YouTube link, so running it twice creates nothing new. Videos are external
 * links (video_source=1), free, without expiry, like the admin would save them.
 */

if ($argc < 3) {
    fwrite(STDERR, "Usage: php import_youtube.php <laravel_root> <bundle_dir> [--dry-run]\n");
    exit(1);
}
$root = realpath($argv[1]);
$bundle = rtrim($argv[2], '/');
$dry = in_array('--dry-run', $argv);

require $root . '/vendor/autoload.php';
$app = require $root . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$batch = json_decode(file_get_contents($bundle . '/batch.json'), true);
$storage = $root . '/storage/app/public/';
$now = now();

function slug($text)
{
    // Must match slug() in make_visuals.py (NFKD, drop accents).
    $text = preg_replace('/\p{Mn}/u', '', Normalizer::normalize($text, Normalizer::FORM_KD));
    return trim(preg_replace('/[^a-z0-9]+/', '_', strtolower($text)), '_');
}

// Same naming as Common::saveImage: <prefix><d_m_Y_><rand>.<ext>
function storeImage($src, $folder, $prefix, $dry)
{
    global $storage;
    if (!is_file($src)) {
        throw new Exception("Visuel manquant : $src");
    }
    do {
        $name = $prefix . date('d_m_Y_') . rand(1111, 9999) . '.jpg';
    } while (is_file($storage . $folder . '/' . $name));
    if (!$dry) {
        is_dir($storage . $folder) || mkdir($storage . $folder, 0755, true);
        copy($src, $storage . $folder . '/' . $name);
    }
    return $name;
}

$stats = ['category' => 0, 'series' => 0, 'video' => 0, 'skipped' => 0];

DB::beginTransaction();
try {
    $categoryIds = [];
    foreach ($batch['categories'] as $name => $mode) {
        $id = DB::table('tbl_category')->where('name', $name)->value('id');
        if (!$id && $mode === 'create') {
            $id = $dry ? -1 : DB::table('tbl_category')->insertGetId([
                'name' => $name,
                'image' => storeImage("$bundle/category_" . slug($name) . '.jpg', 'category', 'category_', $dry),
                'status' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $stats['category']++;
            echo "+ catégorie  $name\n";
        }
        if (!$id) {
            throw new Exception("Catégorie introuvable : $name");
        }
        $categoryIds[$name] = $id;
    }

    $seriesIds = [];
    $seriesCategory = [];
    foreach ($batch['series'] as $s) {
        $id = DB::table('tbl_video_series')->where('title', $s['title'])->value('id');
        if (!$id && !empty($s['existing'])) {
            throw new Exception("Série existante introuvable : {$s['title']}");
        }
        if (!$id) {
            $base = "$bundle/series_" . slug($s['title']);
            $id = $dry ? -1 : DB::table('tbl_video_series')->insertGetId([
                'title' => $s['title'],
                'description' => $s['description'] ?? '',
                'portrait_img' => storeImage($base . '_portrait.jpg', 'video_series', 'video_series_', $dry),
                'landscape_img' => storeImage($base . '_landscape.jpg', 'video_series', 'video_series_', $dry),
                'category_id' => $categoryIds[$s['category']],
                'status' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $stats['series']++;
            echo "+ série      {$s['title']}\n";
        }
        $seriesIds[$s['title']] = $id;
        $seriesCategory[$s['title']] = $categoryIds[$s['category']];
    }

    foreach ($batch['videos'] as $v) {
        $link = 'https://www.youtube.com/watch?v=' . $v['yt'];
        if (DB::table('tbl_live_event')->where('link', $link)->exists()) {
            $stats['skipped']++;
            echo "= déjà là    {$v['title']}\n";
            continue;
        }
        $series = $v['series'] ?? null;
        $base = "$bundle/{$v['yt']}";
        if (!$dry) {
            DB::table('tbl_live_event')->insert([
                'title' => $v['title'],
                'description' => '',
                'portrait_img' => storeImage($base . '_portrait.jpg', 'live_event', 'live_event_', $dry),
                'landscape_img' => storeImage($base . '_landscape.jpg', 'live_event', 'live_event_', $dry),
                'date' => '2099-12-31',
                'start_time' => '00:00',
                'end_time' => '23:59',
                'is_paid' => 0,
                'price' => 0,
                'type' => 2,
                'category_id' => $series ? $seriesCategory[$series] : $categoryIds[$v['category']],
                'video_source' => 1,
                'video_series_id' => $series ? $seriesIds[$series] : null,
                'episode_number' => $series ? $v['episode'] : null,
                'total_view' => 0,
                'link' => $link,
                'status' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
        $stats['video']++;
        echo "+ vidéo      {$v['title']}" . ($series ? "  [$series #{$v['episode']}]" : '') . "\n";
    }

    $dry ? DB::rollBack() : DB::commit();
} catch (Throwable $e) {
    DB::rollBack();
    fwrite(STDERR, 'ERREUR : ' . $e->getMessage() . "\n");
    exit(1);
}

printf("%s%d catégorie(s), %d série(s), %d vidéo(s) ajoutées, %d déjà présentes.\n",
    $dry ? '[DRY-RUN] ' : '', $stats['category'], $stats['series'], $stats['video'], $stats['skipped']);
