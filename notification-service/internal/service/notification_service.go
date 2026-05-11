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

func (s *NotificationService) GetUserNotifications(userID string) ([]model.Notification, error) {
	return s.repo.GetByUserID(userID)
}

func (s *NotificationService) MarkAsRead(id string) error {
	return s.repo.MarkAsRead(id)
}

func (s *NotificationService) MarkAllAsRead(userID string) error {
	return s.repo.MarkAllAsRead(userID)
}

func (s *NotificationService) GetUnreadCount(userID string) (int, error) {
	return s.repo.GetUnreadCount(userID)
}

func (s *NotificationService) DeleteNotification(id string) error {
	return s.repo.Delete(id)
}
