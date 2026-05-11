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
		UserId:    "user-001",
		RouteId:   "route-101",
		RouteName: "Astana City Walk",
		Mood:      "adventurous",
	}

	historyRes, err := routeClient.CreateHistory(ctx, historyReq)
	if err != nil {
		log.Fatalf("CreateHistory failed: %v", err)
	}

	fmt.Println("✅ History created successfully")
	fmt.Println("History ID:", historyRes.History.HistoryId)
	fmt.Println("Route ID:", historyRes.History.RouteId)
	fmt.Println("Mood:", historyRes.History.Mood)
	fmt.Println("Status:", historyRes.History.Status)
	fmt.Println()

	feedbackConn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to feedback-service: %v", err)
	}
	defer feedbackConn.Close()

	feedbackClient := feedbackpb.NewFeedbackServiceClient(feedbackConn)

	feedbackReq := &feedbackpb.CreateFeedbackRequest{
		UserId:     "user-001",
		RouteId:    "route-101",
		LocationId: "location-001",
		Rating:     5,
		Comment:    "Amazing tourist route in Astana!",
	}

	feedbackRes, err := feedbackClient.CreateFeedback(ctx, feedbackReq)
	if err != nil {
		log.Fatalf("CreateFeedback failed: %v", err)
	}

	fmt.Println("✅ Feedback created successfully")
	fmt.Println("Feedback ID:", feedbackRes.Feedback.FeedbackId)
	fmt.Println("Route ID:", feedbackRes.Feedback.RouteId)
	fmt.Println("Location ID:", feedbackRes.Feedback.LocationId)
	fmt.Println("Rating:", feedbackRes.Feedback.Rating)
	fmt.Println("Comment:", feedbackRes.Feedback.Comment)
	fmt.Println()

	updatedHistoryRes, err := routeClient.GetUserHistory(ctx, &routepb.GetUserHistoryRequest{
		UserId: "user-001",
	})
	if err != nil {
		log.Fatalf("GetUserHistory failed: %v", err)
	}

	fmt.Println("✅ Updated history records:")
	for _, h := range updatedHistoryRes.Histories {
		fmt.Printf("History ID: %s | Route: %s | Mood: %s | Status: %s\n",
			h.HistoryId, h.RouteName, h.Mood, h.Status)
	}
}
