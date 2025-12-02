<?php
// handlers/payments.php
function handlePaymentsResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { $stmt = $pdo->prepare('SELECT * FROM payments WHERE id = ?'); $stmt->execute([$id]); respond($stmt->fetch() ?: []); }
        if (isset($_GET['orderId'])) { $stmt = $pdo->prepare('SELECT * FROM payments WHERE orderId = ? ORDER BY createdAt DESC'); $stmt->execute([$_GET['orderId']]); respond($stmt->fetchAll()); }
        respond($pdo->query('SELECT * FROM payments ORDER BY createdAt DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $idVal = $input['id'] ?? bin2hex(random_bytes(8));
        $sql = 'INSERT INTO payments (id, orderId, amount, paymentMethod, status, createdAt, paidAt, qrCodeUrl, paymentReference) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $pdo->prepare($sql)->execute([
            $idVal,
            $input['orderId'] ?? null,
            $input['amount'] ?? 0,
            $input['paymentMethod'] ?? null,
            $input['status'] ?? 0,
            $input['createdAt'] ?? date('c'),
            $input['paidAt'] ?? null,
            $input['qrCodeUrl'] ?? null,
            $input['paymentReference'] ?? null,
        ]);
        respond(['id' => $idVal], 201);
    }
    if ($method === 'PUT') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $parts=[];$params = [];
        foreach (['orderId','amount','paymentMethod','status','createdAt','paidAt','qrCodeUrl','paymentReference'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $pdo->prepare('UPDATE payments SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') { if (!$id) respond(['error'=>'Missing id'],400); $pdo->prepare('DELETE FROM payments WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
}

?>
