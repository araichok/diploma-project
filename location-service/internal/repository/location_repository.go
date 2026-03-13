package repository

import "location-service/internal/model"

type LocationRepository interface {
	Create(location *model.Location) error
	GetByID(id string) (*model.Location, error)
	GetAll() ([]*model.Location, error)
	Delete(id string) error
	Search(city string, category string, minRating float64) ([]*model.Location, error)
}
