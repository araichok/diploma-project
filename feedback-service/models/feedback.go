package models

import "time"

// Feedback represents a user's feedback on a completed route
type Feedback struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	RouteID    string    `json:"route_id"`
	LocationID string    `json:"location_id"`
	Rating     int       `json:"rating"`
	Comment    string    `json:"comment"`
	CreatedAt  time.Time `json:"created_at"`
}
