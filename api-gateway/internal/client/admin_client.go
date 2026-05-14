package client

import (
	adminpb "api-gateway/proto/adminpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func NewAdminClient(address string) (adminpb.AdminServiceClient, error) {
	conn, err := grpc.NewClient(
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)

	if err != nil {
		return nil, err
	}

	return adminpb.NewAdminServiceClient(conn), nil
}
