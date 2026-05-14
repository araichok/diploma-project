package service

import (
	"admin-service/internal/client"
	"admin-service/internal/model"
	"admin-service/internal/repository"
	"fmt"
)

type AdminService struct {
	repo       *repository.AdminRepository
	userClient *client.UserClient
}

func NewAdminService(repo *repository.AdminRepository) *AdminService {
	return &AdminService{
		repo:       repo,
		userClient: client.NewUserClient(),
	}
}

func (s *AdminService) AddAdmin(userID, role string) (*model.Admin, error) {
	// Verify user exists in user-service
	user, err := s.userClient.GetUserProfile(userID)
	if err != nil {
		return nil, fmt.Errorf("user not found: %v", err)
	}
	if user != nil {
		role = user.Role
		if role == "" {
			role = "admin"
		}
	}

	return s.repo.CreateAdmin(userID, role)
}

func (s *AdminService) GetAllAdmins() ([]model.Admin, error) {
	return s.repo.GetAllAdmins()
}

func (s *AdminService) IsAdmin(userID string) (bool, error) {
	return s.repo.IsAdmin(userID)
}

func (s *AdminService) RemoveAdmin(id string) error {
	return s.repo.DeleteAdmin(id)
}

func (s *AdminService) GetSystemStats() (*model.AdminStats, error) {
	return s.repo.GetStats()
}
