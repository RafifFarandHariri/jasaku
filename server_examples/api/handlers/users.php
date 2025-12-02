<?php
// handlers/users.php
// Functions to handle users resource

function handleUsersResource($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            $stmt = $pdo->prepare('SELECT id, nrp, nama, email, phone, profile_image, role, is_verified_provider, provider_since, provider_description, created_at FROM users WHERE id = ?');
            $stmt->execute([$id]);
            respond($stmt->fetch() ?: []);
        }
        $stmt = $pdo->query('SELECT id, nrp, nama, email, phone, profile_image, role, is_verified_provider, provider_since, provider_description, created_at FROM users ORDER BY id DESC');
        respond($stmt->fetchAll());
    }

    if ($method === 'PUT') {
        if (!$id) respond(['error' => 'Missing id'], 400);
        $parts = [];$params = [];
        foreach (['nrp','nama','email','phone','profile_image','role','is_verified_provider','provider_since','provider_description'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $pdo->prepare('UPDATE users SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok' => true]);
    }

    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

?>
