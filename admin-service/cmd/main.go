package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"admin-service/internal/database"
	"admin-service/internal/handler"
	"admin-service/internal/repository"
	"admin-service/internal/service"
	pb "admin-service/proto"

	"google.golang.org/grpc"
)

func main() {
	db := database.Connect()
	defer db.Close()

	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS admins (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL UNIQUE,
			role VARCHAR(50) NOT NULL DEFAULT 'admin',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	`)

	if err != nil {
		log.Fatalf("failed to create table: %v", err)
	}

	repo := repository.NewAdminRepository(db)
	svc := service.NewAdminService(repo)
	grpcHandler := handler.NewAdminGrpcServer(svc)

	port := os.Getenv("PORT")
	if port == "" {
		port = "50058"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterAdminServiceServer(s, grpcHandler)

	fmt.Println("Admin gRPC Service running on port " + port)

	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
