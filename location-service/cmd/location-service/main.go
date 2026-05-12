package main

import (
	"location-service/internal/handler"
	"log"
	"net"

	"location-service/internal/database"
	"location-service/internal/repository"
	"location-service/internal/service"
	locationpb "location-service/proto/locationpb"

	"github.com/joho/godotenv"
	"google.golang.org/grpc"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found")
	}

	db, err := database.ConnectPostgres()
	if err != nil {
		log.Fatalf("failed to connect postgres: %v", err)
	}
	defer db.Close()

	locationRepo := repository.NewLocationRepository(db)

	lis, err := net.Listen("tcp", ":50054")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()

	locationService := service.NewLocationService(locationRepo)
	locationHandler := handler.NewLocationGrpcHandler(locationService)

	locationpb.RegisterLocationServiceServer(grpcServer, locationHandler)
	log.Println("Location service started on port :50054")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
