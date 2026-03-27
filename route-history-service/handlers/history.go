package handlers

import (
	"encoding/json"
	"net/http"

	"route-history-service/models"
	"route-history-service/storage"
)

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
		http.Error(w, "user_id and route_id required", http.StatusBadRequest)
		return
	}

	storage.Histories = append(storage.Histories, history)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(history)
}

func GetHistory(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(storage.Histories)
}