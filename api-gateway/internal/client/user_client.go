package client

import (
	"api-gateway/proto/userpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewUserClient(address string) (userpb.UserServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return userpb.NewUserServiceClient(conn), nil
}
