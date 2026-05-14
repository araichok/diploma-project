package client

import (
	"api-gateway/proto/preferencepb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewPreferenceClient(address string) (preferencepb.PreferenceServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return preferencepb.NewPreferenceServiceClient(conn), nil
}
