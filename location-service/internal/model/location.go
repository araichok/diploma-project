package model

type Location struct {
	ID      int
	PlaceID string
	Name    string
	Type    string
	City    string
	Lat     float64
	Lon     float64
	Mood    string
}
