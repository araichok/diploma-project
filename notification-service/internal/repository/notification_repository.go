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

// new NotificationRepository
func NewNotificationRepository(db *sql.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

// new notif
func (r *NotificationRepository) Create(n *model.Notification) error {
	n.ID = uuid.New().String()
	n.IsRead = false
	n.CreatedAt = time.Now()

	query := `INSERT INTO notifications (id, user_id, message, type, is_read, created_at)
			  VALUES ($1, $2, $3, $4, $5, $6)`

	_, err := r.db.Exec(query,
		n.ID, n.UserID, n.Message, n.Type, n.IsRead, n.CreatedAt,
	)
	return err
}

// specific user
func (r *NotificationRepository) GetByUserID(userID string) ([]model.Notification, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, message, type, is_read, created_at FROM notifications WHERE user_id = $1 ORDER BY created_at DESC`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []model.Notification
	for rows.Next() {
		var n model.Notification
		err := rows.Scan(&n.ID, &n.UserID, &n.Message, &n.Type, &n.IsRead, &n.CreatedAt)
		if err != nil {
			continue
		}
		notifications = append(notifications, n)
	}
	return notifications, nil
}

// read
func (r *NotificationRepository) MarkAsRead(id string) error {
	_, err := r.db.Exec(
		`UPDATE notifications SET is_read = TRUE WHERE id = $1`,
		id,
	)
	return err
}
