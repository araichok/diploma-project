package repository

import (
	"database/sql"
)

type NotificationRepository struct {
	db *sql.DB
}
