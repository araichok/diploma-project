package model

import "time"

type Preference struct {
	ID         int64
	UserID     string
	Mood       string
	Budget     int32
	Duration   int32
	Location   string
	TravelDate string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}
