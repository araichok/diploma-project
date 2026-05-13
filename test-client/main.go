package main

import (
	"context"
	"fmt"
	"log"
	"time"

	adminpb "admin-service/proto"
	feedbackpb "feedback-service/proto"
	notificationpb "notification-service/proto"
	routepb "route-history-service/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	routeConn, err := grpc.Dial("localhost:50056", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to route-history-service: %v", err)
	}
	defer routeConn.Close()
	routeClient := routepb.NewRouteHistoryServiceClient(routeConn)

	historyRes, err := routeClient.CreateHistory(ctx, &routepb.CreateHistoryRequest{
		UserId:    "user-001",
		RouteId:   "route-101",
		RouteName: "Astana City Walk",
		Mood:      "adventurous",
	})
	if err != nil {
		log.Fatalf("CreateHistory failed: %v", err)
	}
	fmt.Println("✅ History created successfully")
	fmt.Println("History ID:", historyRes.History.HistoryId)
	fmt.Println("Status:", historyRes.History.Status)
	fmt.Println()

	feedbackConn, err := grpc.Dial("localhost:50055", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to feedback-service: %v", err)
	}
	defer feedbackConn.Close()
	feedbackClient := feedbackpb.NewFeedbackServiceClient(feedbackConn)

	feedbackRes, err := feedbackClient.CreateFeedback(ctx, &feedbackpb.CreateFeedbackRequest{
		UserId:     "user-001",
		RouteId:    "route-101",
		LocationId: "location-001",
		Rating:     5,
		Comment:    "Amazing tourist route in Astana!",
	})
	if err != nil {
		log.Fatalf("CreateFeedback failed: %v", err)
	}
	fmt.Println("✅ Feedback created successfully")
	fmt.Println("Feedback ID:", feedbackRes.Feedback.FeedbackId)
	fmt.Println("Rating:", feedbackRes.Feedback.Rating)
	fmt.Println("Comment:", feedbackRes.Feedback.Comment)
	fmt.Println()