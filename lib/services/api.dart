// Singleton accessor for ApiClient targeted at local Windows desktop development.
import 'api_client.dart';

// For Windows desktop when API runs on XAMPP on the same machine:
// Use 'http://localhost/jasaku_api/api' (port 80 default). If Apache uses
// another port, include it like 'http://localhost:8080/jasaku_api/api'.
// Use `api.php` router as the base so ApiClient constructs
// requests like `http://localhost/jasaku_api/api.php?resource=...`
// Use the router entrypoint hosted under XAMPP: `jasaku_api/api/api.php`.
// This ensures calls become `http://localhost/jasaku_api/api/api.php?resource=...&action=...`
final ApiClient apiClient = ApiClient('http://localhost/jasaku_api/api/api.php');

// Usage: import 'package:your_app/services/api.dart'; then call
// await apiClient.login(...);
