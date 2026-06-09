package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"user-service/internal/config"

	"github.com/jackc/pgx/v5/pgxpool"
)

func ConnectDB(cfg *config.Config) (*pgxpool.Pool, error) {
	connString := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s pool_max_conns=10",
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
		cfg.DBSSLMode,
	)

	var pool *pgxpool.Pool
	var err error

	for i := 0; i < 10; i++ {
		pool, err = pgxpool.New(context.Background(), connString)
		if err == nil {
			if pingErr := pool.Ping(context.Background()); pingErr == nil {
				log.Println("Connected to PostgreSQL pool")
				return pool, nil
			}
			pool.Close()
		}

		log.Println("Waiting for PostgreSQL...")
		time.Sleep(3 * time.Second)
	}

	return nil, err
}
