<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

function respond(int $status, array $body): never
{
    http_response_code($status);
    echo json_encode($body, JSON_THROW_ON_ERROR);
    exit;
}

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($path !== '/login') {
    respond(404, ['error' => 'notFound']);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    respond(405, ['error' => 'methodNotAllowed']);
}

try {
    $input = json_decode(
        file_get_contents('php://input'),
        associative: true,
        flags: JSON_THROW_ON_ERROR
    );
} catch (JsonException $error) {
    respond(400, ['error' => 'invalidJSON']);
}

if (!is_array($input)) {
    respond(400, ['error' => 'invalidCredentials']);
}

$username = $input['username'] ?? null;
$password = $input['password'] ?? null;

if (
    !is_string($username) ||
    !is_string($password) ||
    $username === '' ||
    $password === ''
) {
    respond(400, ['error' => 'missingCredentials']);
}

try {
    $databasePassword = getenv('CHALLENGE2_DB_PASSWORD');

    if ($databasePassword === false || $databasePassword === '') {
        throw new RuntimeException('Database password is missing.');
    }

    $database = new PDO(
        'mysql:host=localhost;dbname=challenge2;charset=utf8mb4',
        'challenge2_api',
        $databasePassword,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );

    $statement = $database->prepare(
        'SELECT id, username, password_hash
         FROM users
         WHERE username = :username'
    );

    $statement->execute(['username' => $username]);
    $user = $statement->fetch();

    if ($user === false) {
        respond(401, ['error' => 'invalidCredentials']);
    }

    error_log(
        'Password hash settings: ' .
        json_encode(password_get_info($user['password_hash']))
    );

    $startedAt = microtime(true);

    $passwordMatches = password_verify(
        $password,
        $user['password_hash']
    );

    error_log(
        'Password verification seconds: ' .
        (microtime(true) - $startedAt)
    );

    if (!$passwordMatches) {
        respond(401, ['error' => 'invalidCredentials']);
    }

    respond(200, [
        'id' => $user['id'],
        'username' => $user['username'],
        'token' => bin2hex(random_bytes(32)),
        'expiresIn' => 3600,
    ]);
} catch (Throwable $error) {
    error_log((string) $error);
    respond(500, ['error' => 'serverError']);
}
