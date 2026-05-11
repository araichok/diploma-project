package service

import (
	"notification-service/internal/repository"
)

// business logic for notifications
type NotificationService struct {
	repo *repository.NotificationRepository
}

func NewNotificationService(repo *repository.NotificationRepository) *NotificationService {
	return &NotificationService{repo: repo}
}
