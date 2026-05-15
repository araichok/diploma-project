package client

import (
	notificationpb "api-gateway/proto/notificationpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewNotificationClient(address string) (notificationpb.NotificationServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return notificationpb.NewNotificationServiceClient(conn), nil
}
