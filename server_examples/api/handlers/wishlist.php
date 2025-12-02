<?php
// handlers/wishlist.php
function handleWishlistResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if (isset($_GET['userId'])) { $stmt = $pdo->prepare('SELECT * FROM wishlist WHERE userId = ? ORDER BY id DESC'); $stmt->execute([$_GET['userId']]); respond($stmt->fetchAll()); }
        respond($pdo->query('SELECT * FROM wishlist ORDER BY id DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $sql = 'INSERT INTO wishlist (userId, serviceId) VALUES (?, ?)';
        $pdo->prepare($sql)->execute([$input['userId'] ?? null, $input['serviceId'] ?? null]);
        respond(['id' => $pdo->lastInsertId()], 201);
    }
    if ($method === 'DELETE') {
        if ($id) { $pdo->prepare('DELETE FROM wishlist WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
        if (isset($input['userId']) && isset($input['serviceId'])) { $pdo->prepare('DELETE FROM wishlist WHERE userId = ? AND serviceId = ?')->execute([$input['userId'], $input['serviceId']]); respond(['ok'=>true]); }
        respond(['error'=>'Missing id or keys'],400);
    }
}

?>
