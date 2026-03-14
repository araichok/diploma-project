package client

import (
	"context"
	"log"
	"time"

	pb "route-history-service/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type HistoryClient struct {
	client pb.RouteHistoryServiceClient
}

func NewHistoryClient() *HistoryClient {
	conn, err := grpc.Dial("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to route-history-service: %v", err)
	}

	client := pb.NewRouteHistoryServiceClient(conn)

	return &HistoryClient{
		client: client,
	}
}

func (h *HistoryClient) UpdateStatus(routeID string, status string) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req := &pb.UpdateHistoryStatusRequest{
		RouteId: routeID,
		Status:  status,
	}

	_, err := h.client.UpdateHistoryStatus(ctx, req)
	if err != nil {
		log.Println("Error updating history:", err)
	}
}
