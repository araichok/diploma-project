package middleware

import (
	"context"
	"strings"

	"user-service/internal/auth"
	"user-service/internal/config"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func AuthInterceptor(cfg *config.Config) grpc.UnaryServerInterceptor {

	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (interface{}, error) {

		// public methods
		if info.FullMethod == "/user.UserService/Register" ||
			info.FullMethod == "/user.UserService/Login" {

			return handler(ctx, req)
		}

		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, status.Error(codes.Unauthenticated, "missing metadata")
		}

		authHeader := md.Get("authorization")

		if len(authHeader) == 0 {
			return nil, status.Error(codes.Unauthenticated, "authorization token required")
		}

		token := strings.TrimPrefix(authHeader[0], "Bearer ")

		_, err := auth.ValidateToken(token, cfg.JWTSecret)
		if err != nil {
			return nil, status.Error(codes.Unauthenticated, "invalid token")
		}

		return handler(ctx, req)
	}
}
