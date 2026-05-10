package model

// Notification represents a notification sent to a user
type Notification struct {
	ID     string `json:"id"`
	UserID string `json:"user_id"`
}
