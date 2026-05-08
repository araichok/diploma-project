package cache

import (
	"context"
	"fmt"

	"user-service/internal/config"

	"github.com/redis/go-redis/v9"
)

func NewRedisClient(cfg *config.Config) *redis.Client {
	addr := fmt.Sprintf("%s:%s", cfg.RedisHost, cfg.RedisPort)

	client := redis.NewClient(&redis.Options{
		Addr: addr,
	})

	_, err := client.Ping(context.Background()).Result()
	if err != nil {
		panic(err)
	}

	return client
}
