package handlers

import (
	"encoding/json"
	"net/http"

	"feedback-service/models"
	"feedback-service/storage"
)

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

	if feedback.Review == "" {
		http.Error(w, "review cannot be empty", http.StatusBadRequest)
		return
	}

	storage.Feedbacks = append(storage.Feedbacks, feedback)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(feedback)
}

func GetFeedbacks(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(storage.Feedbacks)
}