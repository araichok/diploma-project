package repository

import (
	"database/sql"
	"time"

	"github.com/google/uuid"

	"admin-service/internal/model"
)

type AdminRepository struct {
	db *sql.DB
}

func NewAdminRepository(db *sql.DB) *AdminRepository {
	return &AdminRepository{db: db}
}

func (r *AdminRepository) CreateAdmin(userID, role string) (*model.Admin, error) {
	admin := &model.Admin{
		ID:        uuid.New().String(),
		UserID:    userID,
		Role:      role,
		CreatedAt: time.Now(),
	}

	query := `INSERT INTO admins (id, user_id, role, created_at) VALUES ($1, $2, $3, $4)`
	_, err := r.db.Exec(query, admin.ID, admin.UserID, admin.Role, admin.CreatedAt)
	if err != nil {
		return nil, err
	}
	return admin, nil
}
