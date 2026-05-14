package client

import (
	"context"
	"log"
	"time"

	pb "route-history-service/proto/notification"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type NotificationClient struct {
	client pb.NotificationServiceClient
}

func NewNotificationClient() *NotificationClient {

	conn, err := grpc.Dial(
		"notification-service:50057",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		log.Fatalf("could not connect to notification-service: %v", err)
	}

	return &NotificationClient{
		client: pb.NewNotificationServiceClient(conn),
	}
}

func (n *NotificationClient) SendNotification(userID, message, notifType string) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := n.client.SendNotification(ctx, &pb.SendNotificationRequest{
		UserId:  userID,
		Message: message,
		Type:    notifType,
	})
	if err != nil {
		log.Println("Error sending notification:", err)
	}
}
