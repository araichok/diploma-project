# User Service

User Service is a gRPC-based microservice developed in Go for managing users in the intelligent tourist route generation platform.

The service provides:

- User registration
- User authentication
- JWT authorization
- Refresh token support
- Logout functionality
- User profile management
- Redis caching
- PostgreSQL persistence
- Validation Rules

---

# Technologies

- Go
- gRPC
- PostgreSQL
- Redis
- Docker
- JWT Authentication

---

# Project Structure

```text
user-service/
│
├── cmd/
│   └── user-service/
│       └── main.go
│
├── internal/
│   ├── auth/
│   ├── cache/
│   ├── config/
│   ├── database/
│   ├── handler/
│   ├── middleware/
│   ├── model/
│   ├── repository/
│   └── service/
│
├── migrations/
├── proto/
├── Dockerfile
├── docker-compose.yml
├── .env
└── README.md
```

---

# Features

## Authentication

- Register
- Login
- JWT Access Token
- Refresh Token
- Logout

## User Management

- Get Profile
- Update User
- Delete User
- Change Password

## Security

- Password hashing with bcrypt
- JWT authentication
- JWT access tokens
- Refresh token support
- gRPC Auth Interceptor
- Protected routes
- Request validation

## Caching

Redis is used for caching user profile data.

# Validation Rules

- Password must contain at least 8 characters
- Email must be valid
- First name and last name are required
- User input is validated before processing requests

---

# Database

## PostgreSQL Tables

### users

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### refresh_tokens

```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

# Running the Service

## Start containers

```bash
docker compose up --build
```

---

# Environment Variables

```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=12345
DB_NAME=tourism_ai
DB_SSLMODE=disable

REDIS_HOST=redis
REDIS_PORT=6379

JWT_SECRET=my_super_secret_key
```

---

# gRPC Methods

| Method | Description |
|---|---|
| Register | Create new user |
| Login | Authenticate user |
| GetProfile | Get user profile |
| UpdateUser | Update user data |
| DeleteUser | Delete user |
| RefreshToken | Generate new access token |
| Logout | Logout user |

---

# Authentication Flow

```text
Register
↓
Login
↓
Access Token + Refresh Token
↓
Protected gRPC Methods
↓
Auth Interceptor Validation
↓
Access Granted
```

---

# Redis Caching Flow

```text
GetProfile
↓
Check Redis Cache
↓
If exists → return cached data
↓
Else → fetch from PostgreSQL
↓
Save to Redis
↓
Return response
```

---

# Future Improvements

- Role-based access control
- Email verification
- Multi-device sessions
- Kubernetes deployment
- API Gateway
- NATS communication
- Monitoring and logging
```