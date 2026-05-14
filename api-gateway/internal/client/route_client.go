package client

import (
	"api-gateway/proto/routepb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewRouteClient(address string) (routepb.RouteServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return routepb.NewRouteServiceClient(conn), nil
}
