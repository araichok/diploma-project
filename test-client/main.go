package main

import (
	"context"
	"fmt"
	"log"
	"time"

	feedbackpb "feedback-service/proto"
	routepb "route-history-service/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	routeConn, err := grpc.Dial("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to route-history-service: %v", err)
	}
	defer routeConn.Close()

	routeClient := routepb.NewRouteHistoryServiceClient(routeConn)

	historyReq := &routepb.CreateHistoryRequest{
		UserId:    "1",
		RouteId:   "101",
		RouteName: "Astana City Walk",
	}

	historyRes, err := routeClient.CreateHistory(ctx, historyReq)
	if err != nil {
		log.Fatalf("CreateHistory failed: %v", err)
	}

	fmt.Println("History created successfully")
	fmt.Println("History ID:", historyRes.History.HistoryId)
	fmt.Println("Route ID:", historyRes.History.RouteId)
	fmt.Println("Status before feedback:", historyRes.History.Status)
	fmt.Println()

	feedbackConn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to feedback-service: %v", err)
	}
	defer feedbackConn.Close()

	feedbackClient := feedbackpb.NewFeedbackServiceClient(feedbackConn)

	feedbackReq := &feedbackpb.CreateFeedbackRequest{
		UserId:  "1",
		RouteId: "101",
		Rating:  5,
		Review:  "Amazing tourist route!",
	}

	feedbackRes, err := feedbackClient.CreateFeedback(ctx, feedbackReq)
	if err != nil {
		log.Fatalf("CreateFeedback failed: %v", err)
	}

	fmt.Println("Feedback created successfully")
	fmt.Println("Feedback ID:", feedbackRes.Feedback.FeedbackId)
	fmt.Println("Route ID:", feedbackRes.Feedback.RouteId)
	fmt.Println("Rating:", feedbackRes.Feedback.Rating)
	fmt.Println("Review:", feedbackRes.Feedback.Review)
	fmt.Println()

	updatedHistoryRes, err := routeClient.GetUserHistory(ctx, &routepb.GetUserHistoryRequest{
		UserId: "1",
	})
	if err != nil {
		log.Fatalf("GetUserHistory failed: %v", err)
	}

	fmt.Println("Updated history records:")
	for _, h := range updatedHistoryRes.Histories {
		fmt.Printf("History ID: %s | Route ID: %s | Status: %s\n", h.HistoryId, h.RouteId, h.Status)
	}
}
