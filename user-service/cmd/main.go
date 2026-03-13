package main

import (
	"context"
	"log"
	"net"

	"user-service/internal/handler"
	"user-service/internal/repository"
	"user-service/internal/service"
	pb "user-service/user-service/proto"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"google.golang.org/grpc"
)

func main() {

	// подключение к MongoDB
	client, err := mongo.Connect(
		context.TODO(),
		options.Client().ApplyURI("mongodb://mongo:27017"),
	)
	if err != nil {
		log.Fatal(err)
	}

	db := client.Database("users_db")

	// repository
	userRepo := repository.NewUserRepository(db)

	// service
	userService := service.NewUserService(userRepo)

	// handler
	userHandler := handler.NewUserHandler(userService)

	// gRPC server
	lis, err := net.Listen("tcp", ":50052")
	if err != nil {
		log.Fatal(err)
	}

	grpcServer := grpc.NewServer()

	pb.RegisterUserServiceServer(grpcServer, userHandler)

	log.Println("User Service running on port 50052")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatal(err)
	}
}
