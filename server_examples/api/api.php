<?php
// api.php - simple REST-ish API for Jasaku app
// Usage (assuming placed in XAMPP htdocs/server_examples/api/):
// GET  /api.php?resource=users            -> list users
// GET  /api.php?resource=users&id=1       -> get user
// POST /api.php?resource=users            -> create user (JSON body)
// PUT  /api.php?resource=users&id=1       -> update user (JSON body)
// DELETE /api.php?resource=users&id=1    -> delete user

require_once __DIR__ . '/db.php';

// Basic router that includes handler files under handlers/
require_once __DIR__ . '/handlers/auth.php';
require_once __DIR__ . '/handlers/users.php';
require_once __DIR__ . '/handlers/services.php';
require_once __DIR__ . '/handlers/orders.php';
require_once __DIR__ . '/handlers/payments.php';
require_once __DIR__ . '/handlers/chats.php';
require_once __DIR__ . '/handlers/offers.php';
require_once __DIR__ . '/handlers/wishlist.php';

$method = $_SERVER['REQUEST_METHOD'];

// Allow CORS for local development
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($method === 'OPTIONS') {
    respond(['ok' => true]);
}

// Parse resource & id either from PATH_INFO or query params
$resource = null;
$id = null;
if (!empty($_SERVER['PATH_INFO'])) {
    $parts = array_values(array_filter(explode('/', $_SERVER['PATH_INFO'])));
    if (count($parts) >= 1) $resource = $parts[0];
    if (count($parts) >= 2) $id = $parts[1];
}
if (!$resource) {
    $resource = isset($_GET['resource']) ? $_GET['resource'] : null;
    $id = $id ?? (isset($_GET['id']) ? $_GET['id'] : null);
}

if (!$resource) respond(['error' => 'Missing resource parameter'], 400);

// Read JSON input for POST/PUT
$input = null;
if (in_array($method, ['POST', 'PUT', 'DELETE'])) {
    $input = getJsonInput();
    if ($input === null) $input = $_POST;
}

try {
    switch ($resource) {
        case 'auth':
            handleAuth($pdo, $method, $id, $input);
            break;
        case 'users':
            handleUsersResource($pdo, $method, $id, $input);
            break;
        case 'services':
            handleServicesResource($pdo, $method, $id, $input);
            break;
        case 'orders':
            handleOrdersResource($pdo, $method, $id, $input);
            break;
        case 'payments':
            handlePaymentsResource($pdo, $method, $id, $input);
            break;
        case 'chats':
            handleChatsResource($pdo, $method, $id, $input);
            break;
        case 'offers':
            handleOffersResource($pdo, $method, $id, $input);
            break;
        case 'wishlist':
            handleWishlistResource($pdo, $method, $id, $input);
            break;
        default:
            respond(['error' => 'Unknown resource'], 404);
    }
} catch (Exception $e) {
    respond(['error' => 'Server error', 'message' => $e->getMessage()], 500);
}

// ---------------- Handlers ----------------
function handleUsers($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            $stmt = $pdo->prepare('SELECT * FROM users WHERE id = ?');
            $stmt->execute([$id]);
            $row = $stmt->fetch();
            respond($row ? $row : []);
        } else {
            $stmt = $pdo->query('SELECT * FROM users ORDER BY id DESC');
            respond($stmt->fetchAll());
        }
    }

    if ($method === 'POST') {
        $sql = 'INSERT INTO users (nrp, nama, email, phone, profile_image, role, is_verified_provider, provider_since, provider_description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $input['nrp'] ?? null,
            $input['nama'] ?? '',
            $input['email'] ?? '',
            $input['phone'] ?? null,
            $input['profile_image'] ?? null,
            $input['role'] ?? 'customer',
            isset($input['is_verified_provider']) ? (int)$input['is_verified_provider'] : 0,
            $input['provider_since'] ?? null,
            $input['provider_description'] ?? null,
        ]);
        respond(['id' => $pdo->lastInsertId()], 201);
    }

    if ($method === 'PUT') {
        if (!$id) respond(['error' => 'Missing id'], 400);
        $parts = [];
        $params = [];
        foreach (['nrp','nama','email','phone','profile_image','role','is_verified_provider','provider_since','provider_description'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $sql = 'UPDATE users SET ' . implode(',', $parts) . ' WHERE id = ?';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        respond(['ok' => true]);
    }

    if ($method === 'DELETE') {
        if (!$id) respond(['error' => 'Missing id'], 400);
        $stmt = $pdo->prepare('DELETE FROM users WHERE id = ?');
        $stmt->execute([$id]);
        respond(['ok' => true]);
    }
}

function handleServices($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            $stmt = $pdo->prepare('SELECT * FROM services WHERE id = ?');
            $stmt->execute([$id]);
            respond($stmt->fetch() ?: []);
        } else {
            $rows = $pdo->query('SELECT * FROM services ORDER BY id DESC')->fetchAll();
            respond($rows);
        }
    }
    if ($method === 'POST') {
        $sql = 'INSERT INTO services (title, seller, price, sold, rating, reviews, is_verified, has_fast_response, category) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
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
        if (!$id) respond(['error'=>'Missing id'], 400);
        $parts = [];$params = [];
        foreach (['title','seller','price','sold','rating','reviews','is_verified','has_fast_response','category'] as $f) {
            if (isset($input[$f])) { $parts[] = "`$f` = ?"; $params[] = $input[$f]; }
        }
        if (empty($parts)) respond(['ok'=>true]);
        $params[] = $id;
        $sql = 'UPDATE services SET '.implode(',', $parts).' WHERE id = ?';
        $pdo->prepare($sql)->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM services WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

function handleOrders($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            $stmt = $pdo->prepare('SELECT * FROM orders WHERE id = ?');
            $stmt->execute([$id]);
            respond($stmt->fetch() ?: []);
        }
        // Optional filter by customerId
        if (isset($_GET['customerId'])) {
            $stmt = $pdo->prepare('SELECT * FROM orders WHERE customerId = ? ORDER BY orderDate DESC');
            $stmt->execute([$_GET['customerId']]);
            respond($stmt->fetchAll());
        }
        respond($pdo->query('SELECT * FROM orders ORDER BY orderDate DESC')->fetchAll());
    }
    if ($method === 'POST') {
        // Expect id provided (string) or generate
        $idVal = $input['id'] ?? bin2hex(random_bytes(8));
        $sql = 'INSERT INTO orders (id, serviceId, serviceTitle, sellerId, sellerName, customerId, customerName, price, quantity, notes, status, orderDate, deadline, completedDate, paymentMethod, isPaid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
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
    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM orders WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

function handlePayments($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            respond($pdo->prepare('SELECT * FROM payments WHERE id = ?')->execute([$id]) ? $pdo->prepare('SELECT * FROM payments WHERE id = ?')->fetch() : []);
        }
        if (isset($_GET['orderId'])) {
            $stmt = $pdo->prepare('SELECT * FROM payments WHERE orderId = ? ORDER BY createdAt DESC');
            $stmt->execute([$_GET['orderId']]);
            respond($stmt->fetchAll());
        }
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
    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM payments WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

function handleChats($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) {
            respond($pdo->prepare('SELECT * FROM chats WHERE id = ?')->execute([$id]) ? $pdo->prepare('SELECT * FROM chats WHERE id = ?')->fetch() : []);
        }
        if (isset($_GET['conversationId'])) {
            $stmt = $pdo->prepare('SELECT * FROM chats WHERE conversationId = ? ORDER BY timestamp ASC');
            $stmt->execute([$_GET['conversationId']]);
            respond($stmt->fetchAll());
        }
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
        $params[] = $id;
        $pdo->prepare('UPDATE chats SET '.implode(',', $parts).' WHERE id = ?')->execute($params);
        respond(['ok'=>true]);
    }
    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM chats WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

function handleOffers($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if ($id) { respond($pdo->prepare('SELECT * FROM price_offers WHERE id = ?')->execute([$id]) ? $pdo->prepare('SELECT * FROM price_offers WHERE id = ?')->fetch() : []); }
        if (isset($_GET['serviceId'])) {
            $stmt = $pdo->prepare('SELECT * FROM price_offers WHERE serviceId = ? ORDER BY createdAt DESC');
            $stmt->execute([$_GET['serviceId']]); respond($stmt->fetchAll());
        }
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
    if ($method === 'DELETE') {
        if (!$id) respond(['error'=>'Missing id'],400);
        $pdo->prepare('DELETE FROM price_offers WHERE id = ?')->execute([$id]);
        respond(['ok'=>true]);
    }
}

function handleWishlist($pdo, $method, $id, $input) {
    if ($method === 'GET') {
        if (isset($_GET['userId'])) {
            $stmt = $pdo->prepare('SELECT * FROM wishlist WHERE userId = ? ORDER BY id DESC');
            $stmt->execute([$_GET['userId']]); respond($stmt->fetchAll());
        }
        respond($pdo->query('SELECT * FROM wishlist ORDER BY id DESC')->fetchAll());
    }
    if ($method === 'POST') {
        $sql = 'INSERT INTO wishlist (userId, serviceId) VALUES (?, ?)';
        $pdo->prepare($sql)->execute([$input['userId'] ?? null, $input['serviceId'] ?? null]);
        respond(['id' => $pdo->lastInsertId()], 201);
    }
    if ($method === 'DELETE') {
        if ($id) {
            $pdo->prepare('DELETE FROM wishlist WHERE id = ?')->execute([$id]);
            respond(['ok'=>true]);
        }
        // allow delete by userId+serviceId
        if (isset($input['userId']) && isset($input['serviceId'])) {
            $pdo->prepare('DELETE FROM wishlist WHERE userId = ? AND serviceId = ?')->execute([$input['userId'], $input['serviceId']]);
            respond(['ok'=>true]);
        }
        respond(['error'=>'Missing id or keys'],400);
    }
}

?>
