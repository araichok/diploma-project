package repository

import (
	"database/sql"
	"time"

	"github.com/google/uuid"

	"route-history-service/models"
)

// RouteHistoryRepository handles all database operations for route history
type RouteHistoryRepository struct {
	db *sql.DB
}

// NewRouteHistoryRepository creates a new RouteHistoryRepository
func NewRouteHistoryRepository(db *sql.DB) *RouteHistoryRepository {
	return &RouteHistoryRepository{db: db}
}

// Create saves a new route history entry to the database
func (r *RouteHistoryRepository) Create(h *models.RouteHistory) error {
	h.ID = uuid.New().String()
	h.Status = "planned"
	h.CreatedAt = time.Now()

	query := `INSERT INTO route_histories (id, user_id, route_id, location_id, route_name, mood, status, created_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	_, err := r.db.Exec(query,
		h.ID, h.UserID, h.RouteID, h.LocationID, h.RouteName, h.Mood, h.Status, h.CreatedAt,
	)
	return err
}

// GetAll returns all route history entries
func (r *RouteHistoryRepository) GetAll() ([]models.RouteHistory, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at FROM route_histories`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var histories []models.RouteHistory
	for rows.Next() {
		var h models.RouteHistory
		err := rows.Scan(&h.ID, &h.UserID, &h.RouteID, &h.LocationID, &h.RouteName, &h.Mood, &h.Status, &h.CreatedAt)
		if err != nil {
			continue
		}
		histories = append(histories, h)
	}
	return histories, nil
}

// GetByUserID returns all route history entries for a specific user
func (r *RouteHistoryRepository) GetByUserID(userID string) ([]models.RouteHistory, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at FROM route_histories WHERE user_id = $1`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var histories []models.RouteHistory
	for rows.Next() {
		var h models.RouteHistory
		err := rows.Scan(&h.ID, &h.UserID, &h.RouteID, &h.LocationID, &h.RouteName, &h.Mood, &h.Status, &h.CreatedAt)
		if err != nil {
			continue
		}
		histories = append(histories, h)
	}
	return histories, nil
}

// GetByID returns a single route history entry by ID
func (r *RouteHistoryRepository) GetByID(id string) (*models.RouteHistory, error) {
	var h models.RouteHistory
	err := r.db.QueryRow(
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at FROM route_histories WHERE id = $1`,
		id,
	).Scan(&h.ID, &h.UserID, &h.RouteID, &h.LocationID, &h.RouteName, &h.Mood, &h.Status, &h.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &h, nil
}

// GetByRouteID returns a single route history entry by route ID
func (r *RouteHistoryRepository) GetByRouteID(routeID string) (*models.RouteHistory, error) {
	var h models.RouteHistory

	err := r.db.QueryRow(
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at 
		 FROM route_histories 
		 WHERE route_id = $1`,
		routeID,
	).Scan(
		&h.ID,
		&h.UserID,
		&h.RouteID,
		&h.LocationID,
		&h.RouteName,
		&h.Mood,
		&h.Status,
		&h.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &h, nil
}

// UpdateStatus updates the status of a route history entry
func (r *RouteHistoryRepository) UpdateStatus(routeID string, status string) error {
	var completedAt interface{}
	if status == "completed" {
		completedAt = time.Now()
	}

	_, err := r.db.Exec(
		`UPDATE route_histories SET status = $1, completed_at = $2 WHERE route_id = $3`,
		status, completedAt, routeID,
	)
	return err
}

// Delete removes a route history entry by ID
func (r *RouteHistoryRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM route_histories WHERE id = $1`, id)
	return err
}



func (r *RouteHistoryRepository) CountRoutes() (int, error) {
	var count int

	err := r.db.QueryRow(`SELECT COUNT(*) FROM route_histories`).Scan(&count)
	if err != nil {
		return 0, err
	}

	return count, nil
}