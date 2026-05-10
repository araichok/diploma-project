package main

import (
	"log"
	"net"
	"os"

	"github.com/joho/godotenv"
	"google.golang.org/grpc"

	"preference-service/internal/cache"
	"preference-service/internal/database"
	"preference-service/internal/handler"
	"preference-service/internal/messaging"
	"preference-service/internal/repository"
	"preference-service/internal/service"
	pb "preference-service/proto/preferencepb"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println(".env not loaded, using Docker environment variables")
	}

	db, err := database.ConnectDB()
	if err != nil {
		log.Fatal("Database connection failed:", err)
	}
	defer db.Close()

	redisClient := cache.NewRedisClient()
	defer redisClient.Close()

	preferenceCache := cache.NewPreferenceCache(redisClient)

	userNATSClient, err := messaging.NewUserNATSClient()
	if err != nil {
		log.Fatal("Failed to connect to NATS:", err)
	}

	preferenceRepo := repository.NewPreferenceRepository(db)

	preferenceService := service.NewPreferenceService(
		preferenceRepo,
		userNATSClient,
		preferenceCache,
	)

	preferenceHandler := handler.NewPreferenceHandler(preferenceService)

	grpcPort := os.Getenv("GRPC_PORT")
	if grpcPort == "" {
		grpcPort = "50052"
	}

	listener, err := net.Listen("tcp", ":"+grpcPort)
	if err != nil {
		log.Fatal("Failed to listen:", err)
	}

	grpcServer := grpc.NewServer()

	pb.RegisterPreferenceServiceServer(grpcServer, preferenceHandler)

	log.Println("Preference Service gRPC server started on port", grpcPort)

	if err := grpcServer.Serve(listener); err != nil {
		log.Fatal("Failed to serve gRPC:", err)
	}
}
