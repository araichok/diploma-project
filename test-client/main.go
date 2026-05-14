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
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	userID := "user-001"
	routeID := fmt.Sprintf("route-test-%d", time.Now().Unix())

	routeConn, err := grpc.Dial("localhost:50056", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatal(err)
	}
	defer routeConn.Close()
	routeClient := routepb.NewRouteHistoryServiceClient(routeConn)

	feedbackConn, err := grpc.Dial("localhost:50055", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatal(err)
	}
	defer feedbackConn.Close()
	feedbackClient := feedbackpb.NewFeedbackServiceClient(feedbackConn)

	notifConn, err := grpc.Dial("localhost:50057", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatal(err)
	}
	defer notifConn.Close()
	notifClient := notificationpb.NewNotificationServiceClient(notifConn)

	fmt.Println("STEP 1: Create route history")
	historyRes, err := routeClient.CreateHistory(ctx, &routepb.CreateHistoryRequest{
		UserId:    userID,
		RouteId:   routeID,
		RouteName: "Astana City Walk",
		Mood:      "adventurous",
	})
	if err != nil {
		log.Fatalf("CreateHistory failed: %v", err)
	}

	fmt.Println("History created")
	fmt.Println("Route ID:", historyRes.History.RouteId)
	fmt.Println("Status:", historyRes.History.Status)
	fmt.Println()

	time.Sleep(1 * time.Second)

	fmt.Println("STEP 2: Try feedback while route is planned")
	_, err = feedbackClient.CreateFeedback(ctx, &feedbackpb.CreateFeedbackRequest{
		UserId:     userID,
		RouteId:    routeID,
		LocationId: "location-001",
		Rating:     5,
		Comment:    "Trying to leave feedback before completing route",
	})

	if err != nil {
		fmt.Println("Correct: feedback was denied because route is not completed")
		fmt.Println("Error:", err)
	} else {
		fmt.Println("Wrong: feedback was allowed while route is planned")
	}
	fmt.Println()

	fmt.Println("STEP 3: Update route status to completed")
	updateRes, err := routeClient.UpdateHistoryStatus(ctx, &routepb.UpdateHistoryStatusRequest{
		RouteId: routeID,
		Status:  "completed",
	})
	if err != nil {
		log.Fatalf("UpdateHistoryStatus failed: %v", err)
	}

	fmt.Println("Status updated")
	fmt.Println("New status:", updateRes.History.Status)
	fmt.Println()

	time.Sleep(1 * time.Second)

	fmt.Println("STEP 4: Try feedback after completed")
	feedbackRes, err := feedbackClient.CreateFeedback(ctx, &feedbackpb.CreateFeedbackRequest{
		UserId:     userID,
		RouteId:    routeID,
		LocationId: "location-001",
		Rating:     5,
		Comment:    "Amazing tourist route in Astana!",
	})
	if err != nil {
		log.Fatalf("CreateFeedback after completed failed: %v", err)
	}

	fmt.Println("Feedback created successfully")
	fmt.Println("Feedback ID:", feedbackRes.Feedback.FeedbackId)
	fmt.Println("Comment:", feedbackRes.Feedback.Comment)
	fmt.Println()

	time.Sleep(1 * time.Second)

	fmt.Println("STEP 5: Get user notifications")
	notifs, err := notifClient.GetUserNotifications(ctx, &notificationpb.GetUserNotificationsRequest{
		UserId: userID,
	})
	if err != nil {
		log.Fatalf("GetUserNotifications failed: %v", err)
	}

	fmt.Println("Notifications:")
	for _, n := range notifs.Notifications {
		fmt.Printf("- [%s] %s\n", n.Type, n.Message)
	}

	fmt.Println()
	fmt.Println("STEP 6: Admin service test")

	adminConn, err := grpc.Dial("localhost:50058", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to admin-service: %v", err)
	}
	defer adminConn.Close()

	adminClient := adminpb.NewAdminServiceClient(adminConn)

	adminRes, err := adminClient.AddAdmin(ctx, &adminpb.AddAdminRequest{
		UserId: "user-001",
		Role:   "admin",
	})
	if err != nil {
		log.Fatalf("AddAdmin failed: %v", err)
	}

	fmt.Println("Admin added successfully")
	fmt.Println("Admin ID:", adminRes.Admin.Id)
	fmt.Println("Role:", adminRes.Admin.Role)

	isAdminRes, err := adminClient.IsAdmin(ctx, &adminpb.IsAdminRequest{
		UserId: "user-001",
	})
	if err != nil {
		log.Fatalf("IsAdmin failed: %v", err)
	}

	fmt.Println("Is admin:", isAdminRes.IsAdmin)
}
