package main

import (
	"fmt"
	"log"
	"net"

	"feedback-service/internal/service"
	pb "feedback-service/proto"

	"google.golang.org/grpc"
)

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	feedbackServer := service.NewFeedbackServer()

	pb.RegisterFeedbackServiceServer(grpcServer, feedbackServer)

	fmt.Println("gRPC Feedback Service running on port 50051")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
