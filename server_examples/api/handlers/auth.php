<?php
// handlers/auth.php
// Requires: $pdo, respond(), getJsonInput(), generate_jwt(), verify_jwt(), get_bearer_token()

function handleAuth($pdo, $method, $id, $input) {
    if ($method === 'POST') {
        if (isset($_GET['action']) && $_GET['action'] === 'login') {
            return loginUser($pdo, $input);
        }
        if (isset($_GET['action']) && $_GET['action'] === 'register') {
            return registerUser($pdo, $input);
        }
    }
    respond(['error' => 'Method not allowed'], 405);
}

function registerUser($pdo, $input) {
    if (empty($input['email']) || empty($input['password']) || empty($input['nama'])) {
        respond(['error' => 'Missing fields'], 400);
    }
    // Check email
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $stmt->execute([$input['email']]);
    if ($stmt->fetch()) respond(['error' => 'Email already in use'], 409);

    $password_hash = password_hash($input['password'], PASSWORD_DEFAULT);
    $sql = 'INSERT INTO users (nrp, nama, email, password_hash, phone, profile_image, role) VALUES (?, ?, ?, ?, ?, ?, ?)';
    $pdo->prepare($sql)->execute([
        $input['nrp'] ?? null,
        $input['nama'],
        $input['email'],
        $password_hash,
        $input['phone'] ?? null,
        $input['profile_image'] ?? null,
        $input['role'] ?? 'customer'
    ]);
    respond(['id' => $pdo->lastInsertId()], 201);
}

function loginUser($pdo, $input) {
    if (empty($input['email']) || empty($input['password'])) respond(['error'=>'Missing fields'], 400);
    $stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
    $stmt->execute([$input['email']]);
    $user = $stmt->fetch();
    if (!$user) respond(['error' => 'Invalid credentials'], 401);
    if (empty($user['password_hash']) || !password_verify($input['password'], $user['password_hash'])) {
        respond(['error' => 'Invalid credentials'], 401);
    }
    // generate JWT
    $payload = [
        'sub' => $user['id'],
        'email' => $user['email'],
        'role' => $user['role'] ?? 'customer'
    ];
    $token = generate_jwt($payload, 60*60*24); // 24 hours
    respond(['token' => $token, 'user' => $user]);
}

?>
