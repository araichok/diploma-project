package service

import (
	"notification-service/internal/model"
	"notification-service/internal/repository"
)

type NotificationService struct {
	repo *repository.NotificationRepository
}

func NewNotificationService(repo *repository.NotificationRepository) *NotificationService {
	return &NotificationService{repo: repo}
}

func (s *NotificationService) SendNotification(userID, message, notifType string) (*model.Notification, error) {
	notification := &model.Notification{
		UserID:  userID,
		Message: message,
		Type:    notifType,
	}

	err := s.repo.Create(notification)
	if err != nil {
		return nil, err
	}

	return notification, nil
}

// returns all notifications for a user
func (s *NotificationService) GetUserNotifications(userID string) ([]model.Notification, error) {
	return s.repo.GetByUserID(userID)
}
