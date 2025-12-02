<?php
// Example: server_examples/api_user_profile.php
// Drop this into your webroot, e.g. C:\xampp\htdocs\jasakuapp\api\user\profile.php
// Adjust DB credentials below to match your setup.

header('Content-Type: application/json; charset=utf-8');
// Allow CORS for debugging (restrict in production)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);
if (!$input || empty($input['email'])) {
    echo json_encode(['success' => false, 'message' => 'Missing email field']);
    exit;
}

$email = $input['email'];

// --- Database config: update these ---
$dbHost = '127.0.0.1';
$dbUser = 'root';
$dbPass = '';
$dbName = 'jasaku_db';
// ------------------------------------

$mysqli = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed: ' . $mysqli->connect_error]);
    exit;
}

// Protect against SQL injection by using prepared statement
$stmt = $mysqli->prepare("SELECT id, nrp, nama, email, phone, profile_image, role, is_verified_provider, provider_since, provider_description FROM users WHERE email = ? LIMIT 1");
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB prepare failed']);
    exit;
}

$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    // Normalize field names to what the Flutter client expects
    $data = [
        'id' => (int)$row['id'],
        'nrp' => $row['nrp'] ?? '',
        'nama' => $row['nama'] ?? '',
        'email' => $row['email'] ?? '',
        'phone' => $row['phone'] ?? null,
        'profile_image' => $row['profile_image'] ?? null,
        'role' => $row['role'] ?? 'customer',
        'is_verified_provider' => (bool)$row['is_verified_provider'],
        'provider_since' => $row['provider_since'] ?? null,
        'provider_description' => $row['provider_description'] ?? null,
    ];

    echo json_encode(['success' => true, 'data' => $data]);
} else {
    echo json_encode(['success' => false, 'message' => 'User not found']);
}

$stmt->close();
$mysqli->close();

?>
