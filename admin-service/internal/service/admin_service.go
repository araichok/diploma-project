package service

import (
	"admin-service/internal/model"
	"admin-service/internal/repository"
)

type AdminService struct {
	repo *repository.AdminRepository
}

func NewAdminService(repo *repository.AdminRepository) *AdminService {
	return &AdminService{repo: repo}
}

func (s *AdminService) AddAdmin(userID, role string) (*model.Admin, error) {
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
