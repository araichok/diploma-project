package client

import (
	feedbackpb "api-gateway/proto/feedbackpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewFeedbackClient(address string) (feedbackpb.FeedbackServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return feedbackpb.NewFeedbackServiceClient(conn), nil
}
