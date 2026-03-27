package model

type Preference struct {
	UserID    string `bson:"user_id"`
	Mood      string `bson:"mood"`
	TimeOfDay string `bson:"time_of_day"`
	Budget    string `bson:"budget"`
}
