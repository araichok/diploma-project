package models

type Feedback struct {
	UserID  string `json:"user_id"`
	RouteID string `json:"route_id"`
	Rating  int    `json:"rating"`
	Review  string `json:"review"`
}