package client

import (
	historypb "api-gateway/proto/historypb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewHistoryClient(address string) (historypb.RouteHistoryServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return historypb.NewRouteHistoryServiceClient(conn), nil
}
