package repository

import (
	"database/sql"

	"location-service/internal/model"
)

type LocationRepository struct {
	db *sql.DB
}

func NewLocationRepository(db *sql.DB) *LocationRepository {
	return &LocationRepository{db: db}
}

func (r *LocationRepository) SaveIfNotExists(location model.Location) error {
	query := `
		INSERT INTO locations (place_id, name, type, city, lat, lon, mood)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (place_id) DO NOTHING
	`

	_, err := r.db.Exec(
		query,
		location.PlaceID,
		location.Name,
		location.Type,
		location.City,
		location.Lat,
		location.Lon,
		location.Mood,
	)

	return err
}
