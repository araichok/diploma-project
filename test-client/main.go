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

	// ─── ROUTE HISTORY SERVICE ───
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

	notifConn, err := grpc.Dial("localhost:50057", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to notification-service: %v", err)
	}
	defer notifConn.Close()
	notifClient := notificationpb.NewNotificationServiceClient(notifConn)

	notifs, err := notifClient.GetUserNotifications(ctx, &notificationpb.GetUserNotificationsRequest{
		UserId: "user-001",
	})
	if err != nil {
		log.Fatalf("GetUserNotifications failed: %v", err)
	}
	fmt.Println("✅ Notifications retrieved successfully")
	fmt.Println("Total notifications:", len(notifs.Notifications))
	for _, n := range notifs.Notifications {
		fmt.Printf("  - %s: %s (read: %v)\n", n.Type, n.Message, n.IsRead)
	}
	fmt.Println()

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
	fmt.Println("✅ Admin added successfully")
	fmt.Println("Admin ID:", adminRes.Admin.Id)
	fmt.Println("Role:", adminRes.Admin.Role)
	fmt.Println()

	isAdminRes, err := adminClient.IsAdmin(ctx, &adminpb.IsAdminRequest{
		UserId: "user-001",
	})
	if err != nil {
		log.Fatalf("IsAdmin failed: %v", err)
	}
	fmt.Println("✅ IsAdmin check:")
	fmt.Println("Is admin:", isAdminRes.IsAdmin)
	fmt.Println()

	statsRes, err := adminClient.GetStats(ctx, &adminpb.GetStatsRequest{})
	if err != nil {
		log.Fatalf("GetStats failed: %v", err)
	}
	fmt.Println("✅ System stats:")
	fmt.Println("Total users:", statsRes.TotalUsers)
	fmt.Println("Total routes:", statsRes.TotalRoutes)
	fmt.Println("Total feedbacks:", statsRes.TotalFeedbacks)
	fmt.Println("Total notifications:", statsRes.TotalNotifications)

	_, err = routeClient.UpdateHistoryStatus(ctx, &routepb.UpdateHistoryStatusRequest{
		RouteId: "route-101",
		Status:  "completed",
	})
	if err != nil {
		log.Fatalf("UpdateHistoryStatus failed: %v", err)
	}
	fmt.Println("\n✅ Route status updated to completed!")
}
