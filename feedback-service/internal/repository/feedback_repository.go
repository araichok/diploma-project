package repository

import (
	"database/sql"
	"time"

	"github.com/google/uuid"

	"feedback-service/models"
)

// FeedbackRepository handles all database operations for feedback
type FeedbackRepository struct {
	db *sql.DB
}

// NewFeedbackRepository creates a new FeedbackRepository
func NewFeedbackRepository(db *sql.DB) *FeedbackRepository {
	return &FeedbackRepository{db: db}
}

// Create saves a new feedback to the database
func (r *FeedbackRepository) Create(f *models.Feedback) error {
	f.ID = uuid.New().String()
	f.CreatedAt = time.Now()

	query := `INSERT INTO feedbacks (id, user_id, route_id, location_id, rating, comment, created_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := r.db.Exec(query,
		f.ID, f.UserID, f.RouteID, f.LocationID, f.Rating, f.Comment, f.CreatedAt,
	)
	return err
}

// GetAll returns all feedbacks from the database
func (r *FeedbackRepository) GetAll() ([]models.Feedback, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, route_id, location_id, rating, comment, created_at FROM feedbacks`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feedbacks []models.Feedback
	for rows.Next() {
		var f models.Feedback
		err := rows.Scan(&f.ID, &f.UserID, &f.RouteID, &f.LocationID, &f.Rating, &f.Comment, &f.CreatedAt)
		if err != nil {
			continue
		}
		feedbacks = append(feedbacks, f)
	}
	return feedbacks, nil
}

// GetByUserID returns all feedbacks for a specific user
func (r *FeedbackRepository) GetByUserID(userID string) ([]models.Feedback, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, route_id, location_id, rating, comment, created_at FROM feedbacks WHERE user_id = $1`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feedbacks []models.Feedback
	for rows.Next() {
		var f models.Feedback
		err := rows.Scan(&f.ID, &f.UserID, &f.RouteID, &f.LocationID, &f.Rating, &f.Comment, &f.CreatedAt)
		if err != nil {
			continue
		}
		feedbacks = append(feedbacks, f)
	}
	return feedbacks, nil
}

// GetByRouteID returns all feedbacks for a specific route
func (r *FeedbackRepository) GetByRouteID(routeID string) ([]models.Feedback, error) {
	rows, err := r.db.Query(
		`SELECT id, user_id, route_id, location_id, rating, comment, created_at FROM feedbacks WHERE route_id = $1`,
		routeID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feedbacks []models.Feedback
	for rows.Next() {
		var f models.Feedback
		err := rows.Scan(&f.ID, &f.UserID, &f.RouteID, &f.LocationID, &f.Rating, &f.Comment, &f.CreatedAt)
		if err != nil {
			continue
		}
		feedbacks = append(feedbacks, f)
	}
	return feedbacks, nil
}

func (r *FeedbackRepository) Delete(id string) error {
	_, err := r.db.Exec(`DELETE FROM feedbacks WHERE id = $1`, id)
	return err
}
