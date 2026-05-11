package handler

import (
	"encoding/json"
	"net/http"

	"notification-service/internal/service"
)

type NotificationHandler struct {
	service *service.NotificationService
}

// NewNotificationHandler creates a new NotificationHandler
func NewNotificationHandler(service *service.NotificationService) *NotificationHandler {
	return &NotificationHandler{service: service}
}

// POST /notifications
func (h *NotificationHandler) SendNotification(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		UserID  string `json:"user_id"`
		Message string `json:"message"`
		Type    string `json:"type"`
	}

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	if req.UserID == "" || req.Message == "" || req.Type == "" {
		http.Error(w, "user_id, message and type are required", http.StatusBadRequest)
		return
	}

	notification, err := h.service.SendNotification(req.UserID, req.Message, req.Type)
	if err != nil {
		http.Error(w, "failed to send notification", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(notification)
}

// GET /notifications?user_id=xxx
func (h *NotificationHandler) GetUserNotifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	notifications, err := h.service.GetUserNotifications(userID)
	if err != nil {
		http.Error(w, "failed to fetch notifications", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(notifications)
}

// PUT /notifications/read?id=xxx
func (h *NotificationHandler) MarkAsRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, "id is required", http.StatusBadRequest)
		return
	}

	err := h.service.MarkAsRead(id)
	if err != nil {
		http.Error(w, "failed to mark as read", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "notification marked as read"})
}

// PUT /notifications/read-all?user_id=xxx
func (h *NotificationHandler) MarkAllAsRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	err := h.service.MarkAllAsRead(userID)
	if err != nil {
		http.Error(w, "failed to mark all as read", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "all notifications marked as read"})
}
