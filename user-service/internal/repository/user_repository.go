package repository

import (
	"context"

	"user-service/internal/model"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type UserRepository struct {
	collection *mongo.Collection
}

func NewUserRepository(db *mongo.Database) *UserRepository {
	return &UserRepository{
		collection: db.Collection("users"),
	}
}

func (r *UserRepository) Create(ctx context.Context, user *model.User) error {
	_, err := r.collection.InsertOne(ctx, user)
	return err
}

func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {

	var user model.User

	err := r.collection.FindOne(ctx, bson.M{
		"email": email,
	}).Decode(&user)

	return &user, err
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*model.User, error) {

	var user model.User

	err := r.collection.FindOne(ctx, bson.M{
		"id": id,
	}).Decode(&user)

	return &user, err
}

func (r *UserRepository) Update(ctx context.Context, id string, name string) (*model.User, error) {

	_, err := r.collection.UpdateOne(
		ctx,
		bson.M{"id": id},
		bson.M{"$set": bson.M{"name": name}},
	)

	if err != nil {
		return nil, err
	}

	return r.GetByID(ctx, id)
}
