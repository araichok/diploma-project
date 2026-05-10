package model

//ntfc
type Notification struct {
	ID      string `json:"id"`
	UserID  string `json:"user_id"`
	Message string `json:"message"`
	Type    string `json:"type"`
	IsRead  bool   `json:"is_read"`
}
