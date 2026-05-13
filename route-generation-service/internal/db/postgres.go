package db

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"route-generation-service/internal/config"

	_ "github.com/lib/pq"
)

func ConnectPostgres(cfg *config.Config) (*sql.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.PostgresHost,
		cfg.PostgresPort,
		cfg.PostgresUser,
		cfg.PostgresPassword,
		cfg.PostgresDB,
	)

	var db *sql.DB
	var err error

	for i := 0; i < 10; i++ {
		db, err = sql.Open("postgres", dsn)
		if err != nil {
			log.Println("failed to open postgres:", err)
			time.Sleep(3 * time.Second)
			continue
		}

		err = db.Ping()
		if err == nil {
			log.Println("connected to PostgreSQL")
			return db, nil
		}

		log.Println("waiting for PostgreSQL...")
		time.Sleep(3 * time.Second)
	}

	return nil, err
}
