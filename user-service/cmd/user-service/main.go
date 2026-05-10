package main

import (
	"context"
	"log"
	"net"
	"user-service/internal/messaging"

	"user-service/internal/cache"
	"user-service/internal/config"
	"user-service/internal/database"
	"user-service/internal/handler"
	"user-service/internal/middleware"
	"user-service/internal/repository"
	"user-service/internal/service"
	"user-service/proto/userpb"

	"google.golang.org/grpc"
)

func main() {

	cfg := config.LoadConfig()

	// PostgreSQL
	conn, err := database.ConnectDB(cfg)
	if err != nil {
		log.Fatal(err)
	}

	defer conn.Close(context.Background())

	// Redis
	redisClient := cache.NewRedisClient(cfg)
	defer redisClient.Close()

	// Repository
	userRepo := repository.NewUserRepository(conn)

	err = messaging.StartUserCheckSubscriber(userRepo)
	if err != nil {
		log.Fatal("Failed to start NATS subscriber:", err)
	}

	// Cache
	userCache := cache.NewUserCache(redisClient)

	// Service
	userService := service.NewUserService(
		userRepo,
		userCache,
		cfg.JWTSecret,
	)

	// Handler
	userHandler := handler.NewUserGrpcHandler(userService)

	// Listener
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}

	// gRPC server
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
