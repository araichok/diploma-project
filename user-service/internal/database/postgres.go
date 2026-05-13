package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"user-service/internal/config"

	"github.com/jackc/pgx/v5"
)

func ConnectDB(cfg *config.Config) (*pgx.Conn, error) {
	connString := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
		cfg.DBSSLMode,
	)

	var conn *pgx.Conn
	var err error

	for i := 0; i < 10; i++ {
		conn, err = pgx.Connect(context.Background(), connString)
		if err == nil {
			log.Println("Connected to PostgreSQL")
			return conn, nil
		}

		log.Println("Waiting for PostgreSQL...")
		time.Sleep(3 * time.Second)
	}

	return nil, err
}
