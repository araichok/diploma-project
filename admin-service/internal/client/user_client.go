package client

import (
	"context"
	"log"
	"os"
	"time"

	pb "admin-service/proto/userpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type UserClient struct {
	client pb.UserServiceClient
	conn   *grpc.ClientConn
}

func NewUserClient() *UserClient {
	addr := os.Getenv("USER_SERVICE_ADDR")
	if addr == "" {
		addr = "user-service:50051"
	}

	conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Printf("could not connect to user-service: %v", err)
		return &UserClient{}
	}

	return &UserClient{
		client: pb.NewUserServiceClient(conn),
		conn:   conn,
	}
}

func (c *UserClient) GetUserProfile(userID string) (*pb.UserResponse, error) {
	if c.client == nil {
		return nil, nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	res, err := c.client.GetProfile(ctx, &pb.GetProfileRequest{
		Id: userID,
	})
	if err != nil {
		log.Printf("error getting user profile: %v", err)
		return nil, err
	}

	return res, nil
}

func (c *UserClient) Close() {
	if c.conn != nil {
		c.conn.Close()
	}
}
