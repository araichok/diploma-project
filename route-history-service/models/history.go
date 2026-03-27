package models

type RouteHistory struct {
	UserID  string `json:"user_id"`
	RouteID string `json:"route_id"`
	Status  string `json:"status"`
}
