package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	GRPCPort            string
	PostgresHost        string
	PostgresPort        string
	PostgresUser        string
	PostgresPassword    string
	PostgresDB          string
	NatsURL             string
	LocationServiceAddr string
}

func LoadConfig() *Config {
	_ = godotenv.Load()

	return &Config{
		GRPCPort:            getEnv("GRPC_PORT", "50053"),
		PostgresHost:        getEnv("POSTGRES_HOST", "localhost"),
		PostgresPort:        getEnv("POSTGRES_PORT", "5432"),
		PostgresUser:        getEnv("POSTGRES_USER", "postgres"),
		PostgresPassword:    getEnv("POSTGRES_PASSWORD", "postgres"),
		PostgresDB:          getEnv("POSTGRES_DB", "route_db"),
		NatsURL:             getEnv("NATS_URL", "nats://localhost:4222"),
		LocationServiceAddr: getEnv("LOCATION_SERVICE_ADDR", "localhost:50054"),
	}
}

func getEnv(key string, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
