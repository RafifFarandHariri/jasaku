<?php
// handlers/orders.php
function handleOrdersResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { $stmt = $pdo->prepare('SELECT * FROM orders WHERE id = ?'); $stmt->execute([$id]); respond($stmt->fetch() ?: []); }
        if (isset($_GET['customerId'])) { $stmt = $pdo->prepare('SELECT * FROM orders WHERE customerId = ? ORDER BY orderDate DESC'); $stmt->execute([$_GET['customerId']]); respond($stmt->fetchAll()); }
        respond($pdo->query('SELECT * FROM orders ORDER BY orderDate DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $idVal = $input['id'] ?? bin2hex(random_bytes(8));
        $sql = 'INSERT INTO orders (id, serviceId, serviceTitle, sellerId, sellerName, customerId, customerName, price, quantity, notes, status, orderDate, deadline, completedDate, paymentMethod, isPaid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $pdo->prepare($sql)->execute([
            $idVal,
            $input['serviceId'] ?? null,
            $input['serviceTitle'] ?? null,
            $input['sellerId'] ?? null,
            $input['sellerName'] ?? null,
            $input['customerId'] ?? null,
            $input['customerName'] ?? null,
            $input['price'] ?? 0,
            $input['quantity'] ?? 1,
            $input['notes'] ?? null,
            $input['status'] ?? 0,
            $input['orderDate'] ?? date('c'),
            $input['deadline'] ?? null,
            $input['completedDate'] ?? null,
            $input['paymentMethod'] ?? null,
            isset($input['isPaid']) ? (int)$input['isPaid'] : 0,
        ]);
        respond(['id' => $idVal], 201);
    }
    if ($method === 'PUT') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $parts=[];$params=[];
        foreach (['serviceId','serviceTitle','sellerId','sellerName','customerId','customerName','price','quantity','notes','status','orderDate','deadline','completedDate','paymentMethod','isPaid'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $pdo->prepare('UPDATE orders SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') { if (!$id) respond(['error'=>'Missing id'],400); $pdo->prepare('DELETE FROM orders WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
}

?>
