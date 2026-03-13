package repository

import (
	"context"
	"time"

	"location-service/internal/model"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type MongoRepository struct {
	collection *mongo.Collection
}

func NewMongoRepository(db *mongo.Database) *MongoRepository {
	return &MongoRepository{
		collection: db.Collection("locations"),
	}
}

func (r *MongoRepository) Create(location *model.Location) error {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.collection.InsertOne(ctx, location)
	return err
}

func (r *MongoRepository) GetByID(id string) (*model.Location, error) {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var location model.Location

	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&location)

	return &location, err
}

func (r *MongoRepository) Delete(id string) error {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})

	return err
}

func (r *MongoRepository) GetAll() ([]*model.Location, error) {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := r.collection.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}

	var locations []*model.Location

	for cursor.Next(ctx) {

		var location model.Location

		err := cursor.Decode(&location)
		if err != nil {
			return nil, err
		}

		locations = append(locations, &location)
	}

	return locations, nil
}

func (r *MongoRepository) Search(city string, category string, minRating float64) ([]*model.Location, error) {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{}

	if city != "" {
		filter["city"] = city
	}

	if category != "" {
		filter["category"] = category
	}

	if minRating > 0 {
		filter["rating"] = bson.M{"$gte": minRating}
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	var locations []*model.Location

	for cursor.Next(ctx) {

		var location model.Location

		err := cursor.Decode(&location)
		if err != nil {
			return nil, err
		}

		locations = append(locations, &location)
	}

	return locations, nil
}
