package model

type Notification struct {
	ID      string `json:"id"`
	UserID  string `json:"user_id"`
	Message string `json:"message"`
}
