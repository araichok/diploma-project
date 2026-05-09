package models

import "time"

// RouteHistory represents a user's route history entry
type RouteHistory struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	RouteID     string    `json:"route_id"`
	LocationID  string    `json:"location_id"`
	RouteName   string    `json:"route_name"`
	Mood        string    `json:"mood"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	CompletedAt time.Time `json:"completed_at"`
}
