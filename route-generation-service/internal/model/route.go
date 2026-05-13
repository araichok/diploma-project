package model

import "time"

type Route struct {
	ID            string
	UserID        string
	PreferenceID  string
	Title         string
	Mood          string
	City          string
	TotalBudget   int32
	TotalDuration int32
	CreatedAt     time.Time
	Places        []RoutePlace
}

type RoutePlace struct {
	ID            string
	RouteID       string
	PlaceID       string
	Name          string
	Type          string
	Address       string
	Lat           float64
	Lon           float64
	VisitOrder    int32
	EstimatedTime int32
	EstimatedCost int32
}
