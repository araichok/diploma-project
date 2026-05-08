package database

import (
	"context"
	"fmt"
	"log"

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

	conn, err := pgx.Connect(context.Background(), connString)
	if err != nil {
		return nil, err
	}

	log.Println("Connected to PostgreSQL")

	return conn, nil
}
