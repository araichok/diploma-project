package main

import (
	"fmt"
	"log"
	"net"

	pb "route-history-service/proto"
	"route-history-service/internal/service"

	"google.golang.org/grpc"
)

func main() {
	lis, err := net.Listen("tcp", ":50052")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	historyServer := service.NewRouteHistoryServer()

	pb.RegisterRouteHistoryServiceServer(grpcServer, historyServer)

	fmt.Println("gRPC Route History Service running on port 50052")

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}