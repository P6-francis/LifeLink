<?php

/*
 * Server-only Firebase bridge for the PHP admin dashboard.
 * Keep the service-account JSON outside the public web root and set its path
 * with LIFELINK_FIREBASE_SERVICE_ACCOUNT_PATH.
 */

function firebase_config(string $key, ?string $default = null): ?string {
    $value = getenv($key);
    return $value === false || $value === '' ? $default : $value;
}

function firebase_project_id(): string {
    return firebase_config('LIFELINK_FIREBASE_PROJECT_ID', 'lifelink-66e5b');
}

function firebase_api_key(): string {
    return firebase_config('LIFELINK_FIREBASE_WEB_API_KEY', 'AIzaSyBcyEaXVAdOPd27JB1iLGrPot1z_xs6cu0');
}

function firebase_admin_emails(): array {
    return array_filter(array_map('trim', explode(',', (string) firebase_config('LIFELINK_ADMIN_EMAILS', ''))));
}

function firebase_is_admin_email(string $email): bool {
    return in_array(strtolower($email), array_map('strtolower', firebase_admin_emails()), true);
}

function firebase_base64url(string $value): string {
    return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
}

function firebase_http(string $method, string $url, ?array $payload = null, array $headers = []): array {
    $headers[] = 'Accept: application/json';
    if ($payload !== null) $headers[] = 'Content-Type: application/json';
    $context = stream_context_create(['http' => [
        'method' => $method,
        'header' => implode("\r\n", $headers),
        'content' => $payload === null ? '' : json_encode($payload, JSON_UNESCAPED_SLASHES),
        'ignore_errors' => true,
        'timeout' => 15,
    ]]);
    $body = @file_get_contents($url, false, $context);
    $status = 0;
    foreach ($http_response_header ?? [] as $line) {
        if (preg_match('#^HTTP/\S+\s+(\d+)#', $line, $matches)) $status = (int) $matches[1];
    }
    $decoded = json_decode($body ?: '{}', true);
    if ($status < 200 || $status >= 300) {
        $message = $decoded['error']['message'] ?? 'Firebase request failed.';
        throw new RuntimeException($message);
    }
    return is_array($decoded) ? $decoded : [];
}

function firebase_sign_in(string $email, string $password): array {
    return firebase_http('POST', 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' . rawurlencode(firebase_api_key()), [
        'email' => $email,
        'password' => $password,
        'returnSecureToken' => true,
    ]);
}

function firebase_change_password(string $idToken, string $newPassword): void {
    firebase_http('POST', 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=' . rawurlencode(firebase_api_key()), [
        'idToken' => $idToken,
        'password' => $newPassword,
        'returnSecureToken' => true,
    ]);
}

function firebase_update_display_name(string $idToken, string $displayName): void {
    firebase_http('POST', 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=' . rawurlencode(firebase_api_key()), [
        'idToken' => $idToken,
        'displayName' => $displayName,
        'returnSecureToken' => true,
    ]);
}

function firebase_access_token(): string {
    $cached = $_SESSION['firebase_service_token'] ?? null;
    if (is_array($cached) && ($cached['expires'] ?? 0) > time() + 60) return $cached['token'];
    $path = firebase_config('LIFELINK_FIREBASE_SERVICE_ACCOUNT_PATH');
    if ($path === null || !is_readable($path)) throw new RuntimeException('Firebase service account is not configured on this server.');
    $account = json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
    $now = time();
    $header = firebase_base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $claims = firebase_base64url(json_encode([
        'iss' => $account['client_email'], 'scope' => 'https://www.googleapis.com/auth/datastore',
        'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
    ]));
    $unsigned = $header . '.' . $claims;
    if (!openssl_sign($unsigned, $signature, $account['private_key'], OPENSSL_ALGO_SHA256)) throw new RuntimeException('Unable to sign Firebase credentials.');
    $context = stream_context_create(['http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/x-www-form-urlencoded\r\nAccept: application/json",
        'content' => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $unsigned . '.' . firebase_base64url($signature),
        ]),
        'ignore_errors' => true,
        'timeout' => 15,
    ]]);
    $body = @file_get_contents('https://oauth2.googleapis.com/token', false, $context);
    $token = json_decode($body ?: '{}', true);
    if (!isset($token['access_token'])) throw new RuntimeException($token['error_description'] ?? 'Unable to obtain a Firebase service token.');
    $_SESSION['firebase_service_token'] = ['token' => $token['access_token'], 'expires' => $now + (int) $token['expires_in']];
    return $token['access_token'];
}

function firestore_request(string $method, string $path, ?array $payload = null): array {
    $base = 'https://firestore.googleapis.com/v1/projects/' . rawurlencode(firebase_project_id()) . '/databases/(default)/documents';
    $url = $path === ':runQuery' ? $base . ':runQuery' : $base . '/' . ltrim($path, '/');
    return firebase_http($method, $url, $payload, ['Authorization: Bearer ' . firebase_access_token()]);
}

function firestore_decode_value(array $value): mixed {
    foreach (['stringValue', 'integerValue', 'doubleValue', 'booleanValue', 'timestampValue', 'nullValue'] as $type) {
        if (array_key_exists($type, $value)) return match ($type) {
            'integerValue' => (int) $value[$type], 'doubleValue' => (float) $value[$type],
            'booleanValue' => (bool) $value[$type], 'nullValue' => null, default => $value[$type],
        };
    }
    if (isset($value['mapValue']['fields'])) return firestore_decode_fields($value['mapValue']['fields']);
    if (isset($value['arrayValue']['values'])) return array_map('firestore_decode_value', $value['arrayValue']['values']);
    return null;
}

function firestore_decode_fields(array $fields): array {
    $data = [];
    foreach ($fields as $key => $value) $data[$key] = firestore_decode_value($value);
    return $data;
}

function firestore_encode_value(mixed $value): array {
    if ($value === null) return ['nullValue' => null];
    if (is_bool($value)) return ['booleanValue' => $value];
    if (is_int($value)) return ['integerValue' => (string) $value];
    if (is_float($value)) return ['doubleValue' => $value];
    if (is_array($value)) return ['mapValue' => ['fields' => firestore_encode_fields($value)]];
    return ['stringValue' => (string) $value];
}

function firestore_encode_fields(array $fields): array {
    $encoded = [];
    foreach ($fields as $key => $value) $encoded[$key] = firestore_encode_value($value);
    return $encoded;
}

function firestore_collection_group(string $collectionId): array {
    $result = firestore_request('POST', ':runQuery', ['structuredQuery' => ['from' => [['collectionId' => $collectionId, 'allDescendants' => true]]]]);
    $items = [];
    foreach ($result as $row) {
        if (!isset($row['document'])) continue;
        $document = $row['document'];
        $items[] = ['path' => preg_replace('#^.*/documents/#', '', $document['name']), 'id' => basename($document['name']), 'data' => firestore_decode_fields($document['fields'] ?? [])];
    }
    return $items;
}

function firestore_collection(string $collectionId): array {
    $result = firestore_request('GET', $collectionId);
    return array_map(static fn ($document) => ['path' => preg_replace('#^.*/documents/#', '', $document['name']), 'id' => basename($document['name']), 'data' => firestore_decode_fields($document['fields'] ?? [])], $result['documents'] ?? []);
}

function firestore_document(string $path): ?array {
    try {
        $document = firestore_request('GET', $path);
        return ['path' => preg_replace('#^.*/documents/#', '', $document['name']), 'id' => basename($document['name']), 'data' => firestore_decode_fields($document['fields'] ?? [])];
    } catch (RuntimeException $exception) {
        if (str_contains($exception->getMessage(), 'NOT_FOUND')) return null;
        throw $exception;
    }
}

function firestore_update(string $path, array $fields): void {
    $mask = implode('&', array_map(static fn ($field) => 'updateMask.fieldPaths=' . rawurlencode($field), array_keys($fields)));
    firestore_request('PATCH', $path . '?' . $mask, ['fields' => firestore_encode_fields($fields)]);
}
