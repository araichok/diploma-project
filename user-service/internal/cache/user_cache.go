package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"user-service/internal/model"

	"github.com/redis/go-redis/v9"
)

type UserCache struct {
	redis *redis.Client
}

func NewUserCache(redis *redis.Client) *UserCache {
	return &UserCache{
		redis: redis,
	}
}

func (c *UserCache) SetUser(user *model.User) error {
	key := fmt.Sprintf("user:%s", user.ID)

	data, err := json.Marshal(user)
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

func (c *UserCache) GetUser(userID string) (*model.User, error) {
	key := fmt.Sprintf("user:%s", userID)

	data, err := c.redis.Get(context.Background(), key).Result()
	if err != nil {
		return nil, err
	}

	var user model.User

	err = json.Unmarshal([]byte(data), &user)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (c *UserCache) DeleteUser(userID string) error {
	key := fmt.Sprintf("user:%s", userID)

	return c.redis.Del(context.Background(), key).Err()
}
