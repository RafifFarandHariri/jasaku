<?php
// handlers/services.php
function handleServicesResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { $stmt = $pdo->prepare('SELECT * FROM services WHERE id = ?'); $stmt->execute([$id]); respond($stmt->fetch() ?: []); }
        $rows = $pdo->query('SELECT * FROM services ORDER BY id DESC')->fetchAll(); respond($rows);
    }
    if ($method === 'POST') {
        $sql = 'INSERT INTO services (title, seller, price, sold, rating, reviews, is_verified, has_fast_response, category) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $pdo->prepare($sql)->execute([
            $input['title'] ?? '',
            $input['seller'] ?? '',
            $input['price'] ?? 0,
            $input['sold'] ?? 0,
            $input['rating'] ?? 0,
            $input['reviews'] ?? 0,
            isset($input['is_verified']) ? (int)$input['is_verified'] : 1,
            isset($input['has_fast_response']) ? (int)$input['has_fast_response'] : 1,
            $input['category'] ?? null,
        ]);
        respond(['id' => $pdo->lastInsertId()], 201);
    }
    if ($method === 'PUT') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $parts=[];$params=[];
        foreach (['title','seller','price','sold','rating','reviews','is_verified','has_fast_response','category'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $pdo->prepare('UPDATE services SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') { if (!$id) respond(['error'=>'Missing id'],400); $pdo->prepare('DELETE FROM services WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
}

?>
