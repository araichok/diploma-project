package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"

	"feedback-service/models"
	"feedback-service/storage"
)

// CreateFeedback handles POST /feedback
func CreateFeedback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var feedback models.Feedback

	err := json.NewDecoder(r.Body).Decode(&feedback)
	if err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	if feedback.UserID == "" || feedback.RouteID == "" {
		http.Error(w, "user_id and route_id are required", http.StatusBadRequest)
		return
	}

	if feedback.Rating < 1 || feedback.Rating > 5 {
		http.Error(w, "rating must be between 1 and 5", http.StatusBadRequest)
		return
	}

	if feedback.Comment == "" {
		http.Error(w, "comment cannot be empty", http.StatusBadRequest)
		return
	}

	feedback.ID = uuid.New().String()
	feedback.CreatedAt = time.Now()

	query := `INSERT INTO feedbacks (id, user_id, route_id, location_id, rating, comment, created_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err = storage.DB.Exec(query,
		feedback.ID,
		feedback.UserID,
		feedback.RouteID,
		feedback.LocationID,
		feedback.Rating,
		feedback.Comment,
		feedback.CreatedAt,
	)
	if err != nil {
		http.Error(w, "failed to save feedback", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(feedback)
}

// GetFeedbacks handles GET /feedbacks
func GetFeedbacks(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	rows, err := storage.DB.Query(`SELECT id, user_id, route_id, location_id, rating, comment, created_at FROM feedbacks`)
	if err != nil {
		http.Error(w, "failed to fetch feedbacks", http.StatusInternalServerError)
		return
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(feedbacks)
}

// GetFeedbackByUser handles GET /feedbacks/user?user_id=xxx
func GetFeedbackByUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	rows, err := storage.DB.Query(
		`SELECT id, user_id, route_id, location_id, rating, comment, created_at FROM feedbacks WHERE user_id = $1`,
		userID,
	)
	if err != nil {
		http.Error(w, "failed to fetch feedbacks", http.StatusInternalServerError)
		return
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(feedbacks)
}
