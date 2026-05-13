package main

import (
	"fmt"
	"log"
	"net"

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

	lis, err := net.Listen("tcp", ":50055")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterFeedbackServiceServer(grpcServer, feedbackService)

	fmt.Println("gRPC Feedback Service running on port 50055")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
