package model

type User struct {
	ID       string `bson:"id"`
	Email    string `bson:"email"`
	Password string `bson:"password"`
	Name     string `bson:"name"`
	Role     string `bson:"role"`
}
