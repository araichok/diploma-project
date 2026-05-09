package storage

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func InitDB() {
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")
	dbname := getEnv("DB_NAME", "feedback_db")

	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname,
	)

	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("database is not reachable: %v", err)
	}

	log.Println("connected to PostgreSQL successfully")
	createTables()
}

func createTables() {
	query := `
	CREATE TABLE IF NOT EXISTS feedbacks (
		id VARCHAR(36) PRIMARY KEY,
		user_id VARCHAR(36) NOT NULL,
		route_id VARCHAR(36) NOT NULL,
		location_id VARCHAR(36),
		rating INT CHECK (rating >= 1 AND rating <= 5),
		comment TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);`

	_, err := DB.Exec(query)
	if err != nil {
		log.Fatalf("failed to create feedbacks table: %v", err)
	}

	log.Println("feedbacks table ready")
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
