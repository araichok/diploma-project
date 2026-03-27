package repository

import (
	"context"
	"time"

	"preference-service/internal/model"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type PreferenceRepository struct {
	collection *mongo.Collection
}

func NewPreferenceRepository(db *mongo.Database) *PreferenceRepository {
	return &PreferenceRepository{
		collection: db.Collection("preferences"),
	}
}

// 💾 сохранить
func (r *PreferenceRepository) Save(pref model.Preference) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.collection.InsertOne(ctx, pref)
	return err
}

// 📥 получить
func (r *PreferenceRepository) GetByUserID(userID string) (model.Preference, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var pref model.Preference

	err := r.collection.FindOne(ctx, bson.M{"user_id": userID}).Decode(&pref)
	return pref, err
}
