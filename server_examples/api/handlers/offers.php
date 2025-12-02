<?php
// handlers/offers.php
function handleOffersResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { $stmt = $pdo->prepare('SELECT * FROM price_offers WHERE id = ?'); $stmt->execute([$id]); respond($stmt->fetch() ?: []); }
        if (isset($_GET['serviceId'])) { $stmt = $pdo->prepare('SELECT * FROM price_offers WHERE serviceId = ? ORDER BY createdAt DESC'); $stmt->execute([$_GET['serviceId']]); respond($stmt->fetchAll()); }
        respond($pdo->query('SELECT * FROM price_offers ORDER BY createdAt DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $idVal = $input['id'] ?? bin2hex(random_bytes(8));
        $sql = 'INSERT INTO price_offers (id, serviceId, originalPrice, proposedPrice, message, status, createdAt, respondedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
        $pdo->prepare($sql)->execute([
            $idVal,
            $input['serviceId'] ?? null,
            $input['originalPrice'] ?? 0,
            $input['proposedPrice'] ?? 0,
            $input['message'] ?? null,
            $input['status'] ?? 0,
            $input['createdAt'] ?? date('c'),
            $input['respondedAt'] ?? null,
        ]);
        respond(['id' => $idVal], 201);
    }
    if ($method === 'PUT') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $parts=[];$params=[];
        foreach (['serviceId','originalPrice','proposedPrice','message','status','createdAt','respondedAt'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $pdo->prepare('UPDATE price_offers SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') { if (!$id) respond(['error'=>'Missing id'],400); $pdo->prepare('DELETE FROM price_offers WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
}

?>
