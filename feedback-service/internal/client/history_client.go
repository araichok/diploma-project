package client

import (
	"context"
	"log"
	"os"
	"time"

	pb "feedback-service/proto/routehistory"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type HistoryClient struct {
	client pb.RouteHistoryServiceClient
}

func NewHistoryClient() *HistoryClient {
	addr := os.Getenv("ROUTE_HISTORY_SERVICE_ADDR")
	if addr == "" {
		addr = "route-history-service:50056"
	}

	conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
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

func (h *HistoryClient) CheckRouteCompleted(routeID string) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	res, err := h.client.CheckRouteCompleted(ctx, &pb.CheckRouteCompletedRequest{
		RouteId: routeID,
	})
	if err != nil {
		log.Println("Error checking route status:", err)
		return false, err
	}

	return res.IsCompleted, nil
}
