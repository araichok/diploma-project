package client

import (
	"context"
	"log"
	"os"
	"time"

	pb "route-history-service/proto/routegeneration"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type RouteGenerationClient struct {
	client pb.RouteServiceClient
	conn   *grpc.ClientConn
}

func NewRouteGenerationClient() *RouteGenerationClient {
	addr := os.Getenv("ROUTE_GENERATION_SERVICE_ADDR")
	if addr == "" {
		addr = "localhost:50053"
	}

	conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("could not connect to route-generation-service: %v", err)
		return &RouteGenerationClient{}
	}

	return &RouteGenerationClient{
		client: pb.NewRouteServiceClient(conn),
		conn:   conn,
	}
}

func (c *RouteGenerationClient) GetRouteByID(routeID string) (*pb.Route, error) {
	if c.client == nil {
		return nil, nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	res, err := c.client.GetRouteByID(ctx, &pb.GetRouteByIDRequest{
		RouteId: routeID,
	})
	if err != nil {
		log.Printf("error getting route: %v", err)
		return nil, err
	}

	return res.Route, nil
}

func (c *RouteGenerationClient) Close() {
	if c.conn != nil {
		c.conn.Close()
	}
}
