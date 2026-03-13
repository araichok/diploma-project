package service

import (
	"location-service/internal/model"
	"location-service/internal/repository"
)

type LocationService struct {
	repo repository.LocationRepository
}

func NewLocationService(repo repository.LocationRepository) *LocationService {
	return &LocationService{repo: repo}
}

func (s *LocationService) CreateLocation(location *model.Location) error {
	return s.repo.Create(location)
}

func (s *LocationService) GetLocation(id string) (*model.Location, error) {
	return s.repo.GetByID(id)
}

func (s *LocationService) GetAllLocations() ([]*model.Location, error) {
	return s.repo.GetAll()
}

func (s *LocationService) DeleteLocation(id string) error {
	return s.repo.Delete(id)
}

func (s *LocationService) ListLocations() ([]*model.Location, error) {
	return s.repo.GetAll()
}

func (s *LocationService) SearchLocations(city, category string, rating float64) ([]*model.Location, error) {
	return s.repo.Search(city, category, rating)
}
