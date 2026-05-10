package repository

import (
	"context"
	"time"

	"user-service/internal/model"

	"github.com/jackc/pgx/v5"
)

type UserRepository struct {
	db *pgx.Conn
}

func NewUserRepository(db *pgx.Conn) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) CreateUser(user *model.User) error {
	query := `
		INSERT INTO users (first_name, last_name, email, password_hash)
		VALUES ($1, $2, $3, $4)
		RETURNING id, role, created_at, updated_at
	`

	return r.db.QueryRow(
		context.Background(),
		query,
		user.FirstName,
		user.LastName,
		user.Email,
		user.PasswordHash,
	).Scan(
		&user.ID,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
}

func (r *UserRepository) GetUserByEmail(email string) (*model.User, error) {
	query := `
		SELECT id, first_name, last_name, email, password_hash, role, created_at, updated_at
		FROM users
		WHERE email = $1
	`

	var user model.User

	err := r.db.QueryRow(context.Background(), query, email).Scan(
		&user.ID,
		&user.FirstName,
		&user.LastName,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) GetUserByID(id string) (*model.User, error) {
	query := `
		SELECT id, first_name, last_name, email, password_hash, role, created_at, updated_at
		FROM users
		WHERE id = $1
	`

	var user model.User

	err := r.db.QueryRow(context.Background(), query, id).Scan(
		&user.ID,
		&user.FirstName,
		&user.LastName,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) UpdateUser(id string, req model.UpdateUserRequest) (*model.User, error) {
	query := `
		UPDATE users
		SET first_name = $1,
		    last_name = $2,
		    email = $3,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $4
		RETURNING id, first_name, last_name, email, password_hash, role, created_at, updated_at
	`

	var user model.User

	err := r.db.QueryRow(
		context.Background(),
		query,
		req.FirstName,
		req.LastName,
		req.Email,
		id,
	).Scan(
		&user.ID,
		&user.FirstName,
		&user.LastName,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (r *UserRepository) DeleteUser(id string) error {
	query := `
		DELETE FROM users
		WHERE id = $1
	`

	_, err := r.db.Exec(context.Background(), query, id)
	return err
}

func (r *UserRepository) SaveRefreshToken(userID, token string, expiresAt time.Time) error {
	query := `
		INSERT INTO refresh_tokens (user_id, token, expires_at)
		VALUES ($1, $2, $3)
	`

	_, err := r.db.Exec(context.Background(), query, userID, token, expiresAt)
	return err
}

func (r *UserRepository) GetRefreshToken(token string) (string, error) {
	query := `
		SELECT user_id
		FROM refresh_tokens
		WHERE token = $1 AND expires_at > CURRENT_TIMESTAMP
	`

	var userID string

	err := r.db.QueryRow(context.Background(), query, token).Scan(&userID)
	if err != nil {
		return "", err
	}

	return userID, nil
}

func (r *UserRepository) DeleteRefreshToken(token string) error {
	query := `
		DELETE FROM refresh_tokens
		WHERE token = $1
	`

	_, err := r.db.Exec(context.Background(), query, token)
	return err
}

func (r *UserRepository) UpdatePassword(userID, passwordHash string) error {
	query := `
		UPDATE users
		SET password_hash = $1,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $2
	`

	_, err := r.db.Exec(
		context.Background(),
		query,
		passwordHash,
		userID,
	)

	return err
}

func (r *UserRepository) ExistsByID(id string) (bool, error) {
	var exists bool

	query := `
		SELECT EXISTS(
			SELECT 1 FROM users WHERE id = $1
		)
	`

	err := r.db.QueryRow(context.Background(), query, id).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}
