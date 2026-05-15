package client

import (
	"context"
	"log"
	"os"
	"time"

	pb "feedback-service/proto/notification"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type NotificationClient struct {
	client pb.NotificationServiceClient
}

func NewNotificationClient() *NotificationClient {
	addr := os.Getenv("NOTIFICATION_SERVICE_ADDR")
	if addr == "" {
		addr = "notification-service:50057"
	}

	conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect to notification-service: %v", err)
	}

	client := pb.NewNotificationServiceClient(conn)

	return &NotificationClient{
		client: client,
	}
}

func (n *NotificationClient) SendNotification(userID, message, notifType string) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req := &pb.SendNotificationRequest{
		UserId:  userID,
		Message: message,
		Type:    notifType,
	}

	_, err := n.client.SendNotification(ctx, req)
	if err != nil {
		log.Println("Error sending notification:", err)
	}
}
