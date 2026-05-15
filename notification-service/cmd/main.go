package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"notification-service/internal/database"
	"notification-service/internal/handler"
	"notification-service/internal/repository"
	"notification-service/internal/service"
	pb "notification-service/proto"

	"google.golang.org/grpc"
)

func main() {
	db := database.Connect()
	defer db.Close()

	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS notifications (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL,
			message TEXT NOT NULL,
			type VARCHAR(50) NOT NULL,
			is_read BOOLEAN DEFAULT FALSE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	`)

	if err != nil {
		log.Fatalf("failed to create table: %v", err)
	}

	repo := repository.NewNotificationRepository(db)
	svc := service.NewNotificationService(repo)
	grpcHandler := handler.NewNotificationGrpcServer(svc)

	port := os.Getenv("PORT")
	if port == "" {
		port = "50057"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterNotificationServiceServer(s, grpcHandler)

	fmt.Println("Notification gRPC Service running on port " + port)

	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
