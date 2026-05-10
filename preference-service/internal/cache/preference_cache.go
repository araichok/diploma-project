package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"preference-service/internal/model"

	"github.com/redis/go-redis/v9"
)

type PreferenceCache struct {
	redis *redis.Client
}

func NewPreferenceCache(redis *redis.Client) *PreferenceCache {
	return &PreferenceCache{redis: redis}
}

func (c *PreferenceCache) GetHistory(userID string) ([]*model.Preference, error) {
	key := fmt.Sprintf("preference:history:%s", userID)

	data, err := c.redis.Get(context.Background(), key).Result()
	if err != nil {
		return nil, err
	}

	var preferences []*model.Preference

	err = json.Unmarshal([]byte(data), &preferences)
	if err != nil {
		return nil, err
	}

	return preferences, nil
}

func (c *PreferenceCache) SetHistory(userID string, preferences []*model.Preference) error {
	key := fmt.Sprintf("preference:history:%s", userID)

	data, err := json.Marshal(preferences)
	if err != nil {
		return err
	}

	return c.redis.Set(
		context.Background(),
		key,
		data,
		10*time.Minute,
	).Err()
}

func (c *PreferenceCache) DeleteHistory(userID string) error {
	key := fmt.Sprintf("preference:history:%s", userID)

	return c.redis.Del(context.Background(), key).Err()
}
