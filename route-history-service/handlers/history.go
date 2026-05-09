package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"

	"route-history-service/models"
	"route-history-service/storage"
)

// CreateHistory handles POST /history
func CreateHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var history models.RouteHistory
	err := json.NewDecoder(r.Body).Decode(&history)
	if err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	if history.UserID == "" || history.RouteID == "" {
		http.Error(w, "user_id and route_id are required", http.StatusBadRequest)
		return
	}

	history.ID = uuid.New().String()
	history.Status = "planned"
	history.CreatedAt = time.Now()

	query := `INSERT INTO route_histories (id, user_id, route_id, location_id, route_name, mood, status, created_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	_, err = storage.DB.Exec(query,
		history.ID,
		history.UserID,
		history.RouteID,
		history.LocationID,
		history.RouteName,
		history.Mood,
		history.Status,
		history.CreatedAt,
	)
	if err != nil {
		http.Error(w, "failed to save history", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(history)
}

// GetHistory handles GET /history
func GetHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	rows, err := storage.DB.Query(
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at FROM route_histories`,
	)
	if err != nil {
		http.Error(w, "failed to fetch history", http.StatusInternalServerError)
		return
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(histories)
}

// GetHistoryByUser handles GET /history/user?user_id=xxx
func GetHistoryByUser(w http.ResponseWriter, r *http.Request) {
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
		`SELECT id, user_id, route_id, location_id, route_name, mood, status, created_at FROM route_histories WHERE user_id = $1`,
		userID,
	)
	if err != nil {
		http.Error(w, "failed to fetch history", http.StatusInternalServerError)
		return
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(histories)
}

// UpdateStatus handles PUT /history/status
func UpdateStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		RouteID string `json:"route_id"`
		Status  string `json:"status"`
	}

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	_, err = storage.DB.Exec(
		`UPDATE route_histories SET status = $1 WHERE route_id = $2`,
		req.Status, req.RouteID,
	)
	if err != nil {
		http.Error(w, "failed to update status", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "status updated"})
}
