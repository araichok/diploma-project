package main

import (
	"context"
	"log"
	"net"

	"user-service/internal/config"
	"user-service/internal/database"
	"user-service/internal/handler"
	"user-service/internal/repository"
	"user-service/internal/service"
	"user-service/proto/userpb"

	"google.golang.org/grpc"

	"user-service/internal/middleware"
)

func main() {

	cfg := config.LoadConfig()

	conn, err := database.ConnectDB(cfg)
	if err != nil {
		log.Fatal(err)
	}

	defer conn.Close(context.Background())

	userRepo := repository.NewUserRepository(conn)

	userService := service.NewUserService(userRepo, cfg.JWTSecret)

	userHandler := handler.NewUserGrpcHandler(userService)

	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}

	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(
			middleware.AuthInterceptor(cfg),
		),
	)

	userpb.RegisterUserServiceServer(grpcServer, userHandler)

	log.Println("User Service running on port 50051")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatal(err)
	}
}
