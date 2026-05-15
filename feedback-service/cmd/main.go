package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"feedback-service/internal/repository"
	"feedback-service/internal/service"
	pb "feedback-service/proto"
	"feedback-service/storage"

	"google.golang.org/grpc"
)

func main() {
	storage.InitDB()

	repo := repository.NewFeedbackRepository(storage.DB)
	feedbackService := service.NewFeedbackService(repo)

	port := os.Getenv("PORT")
	if port == "" {
		port = "50055"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterFeedbackServiceServer(grpcServer, feedbackService)

	fmt.Println("gRPC Feedback Service running on port " + port)

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
