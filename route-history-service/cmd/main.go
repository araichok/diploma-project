package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"route-history-service/internal/repository"
	"route-history-service/internal/service"
	pb "route-history-service/proto"
	"route-history-service/storage"

	"google.golang.org/grpc"
)

func main() {
	storage.InitDB()

	repo := repository.NewRouteHistoryRepository(storage.DB)
	historyService := service.NewRouteHistoryService(repo)

	port := os.Getenv("PORT")
	if port == "" {
		port = "50056"
	}

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterRouteHistoryServiceServer(grpcServer, historyService)

	fmt.Println("gRPC Route History Service running on port " + port)

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
