Jasaku API (Simple PHP + MySQL)
================================

Files created:
- `database.sql` — MySQL schema for `jasaku_db` (create/import in phpMyAdmin)
- `api/db.php` — PDO connection helper
- `api/api.php` — simple REST-ish API (resource-based)

Quick setup (XAMPP):

1. Start Apache and MySQL in XAMPP.
2. Create a database named `jasaku_db` (or change `DB_NAME` in `api/db.php`).
3. Import `database.sql` into the database (via phpMyAdmin -> Import).
4. Place `server_examples` folder under `htdocs` (or copy `server_examples/api` contents to a folder inside `htdocs`).
   Example path: `C:\xampp\htdocs\jasaku_api\` then your `api.php` accessible at `http://localhost/jasaku_api/api/api.php`
5. Edit `api/db.php` to set correct DB credentials if needed.

Examples
--------

List users:
```
GET http://localhost/jasaku_api/api/api.php?resource=users
```

Get user by id:
```
GET http://localhost/jasaku_api/api/api.php?resource=users&id=1
```

Create user (JSON POST):
```
POST http://localhost/jasaku_api/api/api.php?resource=users
Content-Type: application/json

{ "nama": "Budi", "email": "budi@example.com", "nrp": "001" }
```

Create order example:
```
POST http://localhost/jasaku_api/api/api.php?resource=orders
Content-Type: application/json

{ "serviceId": 1, "serviceTitle": "Desain Logo", "sellerId": "10", "sellerName": "Fulan", "customerId": "5", "customerName": "Budi", "price": 100000 }
```

Notes & Improvements
- This API is intentionally minimal for local/dev usage.
- For production, add:
  - Input validation and stricter types
  - Authentication (JWT/session)
  - Request rate limiting, logging, and error handling
  - Use prepared statements everywhere (we used prepared statements via PDO)
  - Transaction handling where necessary (e.g., create order + payment)

If you want, I can:
- Add authentication endpoints (login/register) with password hashing
- Add example Flutter code showing how to call these endpoints
- Expand the API into separate endpoint files (users.php, orders.php) with routing
