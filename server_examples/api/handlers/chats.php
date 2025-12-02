<?php
// handlers/chats.php
function handleChatsResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { $stmt = $pdo->prepare('SELECT * FROM chats WHERE id = ?'); $stmt->execute([$id]); respond($stmt->fetch() ?: []); }
        if (isset($_GET['conversationId'])) { $stmt = $pdo->prepare('SELECT * FROM chats WHERE conversationId = ? ORDER BY timestamp ASC'); $stmt->execute([$_GET['conversationId']]); respond($stmt->fetchAll()); }
        respond($pdo->query('SELECT * FROM chats ORDER BY timestamp DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $idVal = $input['id'] ?? bin2hex(random_bytes(8));
        $sql = 'INSERT INTO chats (id, conversationId, text, isMe, timestamp, type, senderName, serviceId, proposedPrice, offerId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $pdo->prepare($sql)->execute([
            $idVal,
            $input['conversationId'] ?? null,
            $input['text'] ?? null,
            isset($input['isMe']) ? (int)$input['isMe'] : 0,
            $input['timestamp'] ?? date('c'),
            $input['type'] ?? 0,
            $input['senderName'] ?? null,
            $input['serviceId'] ?? null,
            $input['proposedPrice'] ?? null,
            $input['offerId'] ?? null,
        ]);
        respond(['id' => $idVal], 201);
    }
    if ($method === 'PUT') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $parts=[];$params=[];
        foreach (['conversationId','text','isMe','timestamp','type','senderName','serviceId','proposedPrice','offerId'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id; $pdo->prepare('UPDATE chats SET '.implode(',', $parts).' WHERE id = ?')->execute($params); respond(['ok'=>true]);
    }
    if ($method === 'DELETE') { if (!$id) respond(['error'=>'Missing id'],400); $pdo->prepare('DELETE FROM chats WHERE id = ?')->execute([$id]); respond(['ok'=>true]); }
}

?>
