package model

import "time"

type Admin struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
}

type AdminStats struct {
	TotalUsers         int `json:"total_users"`
	TotalRoutes        int `json:"total_routes"`
	TotalFeedbacks     int `json:"total_feedbacks"`
	TotalNotifications int `json:"total_notifications"`
}
