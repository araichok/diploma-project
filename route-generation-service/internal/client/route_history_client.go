package client

import (
	"context"

	routehistorypb "route-generation-service/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type RouteHistoryClient struct {
	conn   *grpc.ClientConn
	client routehistorypb.RouteHistoryServiceClient
}

func NewRouteHistoryClient(address string) (*RouteHistoryClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, err
	}

	return &RouteHistoryClient{
		conn:   conn,
		client: routehistorypb.NewRouteHistoryServiceClient(conn),
	}, nil
}

func (c *RouteHistoryClient) Close() error {
	return c.conn.Close()
}

func (c *RouteHistoryClient) CreateHistory(
	ctx context.Context,
	userID string,
	routeID string,
	routeName string,
	mood string,
) error {
	_, err := c.client.CreateHistory(ctx, &routehistorypb.CreateHistoryRequest{
		UserId:    userID,
		RouteId:   routeID,
		RouteName: routeName,
		Mood:      mood,
	})
	return err
}
