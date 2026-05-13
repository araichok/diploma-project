package client

import (
	"context"

	locationpb "route-generation-service/proto/locationpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type LocationClient struct {
	conn   *grpc.ClientConn
	client locationpb.LocationServiceClient
}

func NewLocationClient(address string) (*LocationClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, err
	}

	return &LocationClient{
		conn:   conn,
		client: locationpb.NewLocationServiceClient(conn),
	}, nil
}

func (c *LocationClient) Close() error {
	return c.conn.Close()
}

func (c *LocationClient) FindSuitableLocations(
	ctx context.Context,
	mood string,
	date string,
	budget float64,
	duration int32,
	location string,
) (*locationpb.FindLocationsResponse, error) {
	return c.client.FindSuitableLocations(ctx, &locationpb.FindLocationsRequest{
		Mood:     mood,
		Date:     date,
		Budget:   budget,
		Duration: duration,
		Location: location,
	})
}
