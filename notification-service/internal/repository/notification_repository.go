package repository

import (
	"database/sql"
	"time"

	"github.com/google/uuid"

	"notification-service/internal/model"
)

type NotificationRepository struct {
	db *sql.DB
}

func NewNotificationRepository(db *sql.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) Create(n *model.Notification) error {
	n.ID = uuid.New().String()
	n.IsRead = false
	n.CreatedAt = time.Now()