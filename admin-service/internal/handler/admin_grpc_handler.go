package handler

import (
	"context"
	"time"

	"admin-service/internal/service"
	pb "admin-service/proto"
)

// AdminGrpcServer implements the gRPC server
type AdminGrpcServer struct {
	pb.UnimplementedAdminServiceServer
	service *service.AdminService
}

// NewAdminGrpcServer creates a new gRPC server
func NewAdminGrpcServer(service *service.AdminService) *AdminGrpcServer {
	return &AdminGrpcServer{service: service}
}

// AddAdmin handles gRPC AddAdmin request
func (s *AdminGrpcServer) AddAdmin(ctx context.Context, req *pb.AddAdminRequest) (*pb.AdminResponse, error) {
	admin, err := s.service.AddAdmin(req.UserId, req.Role)
	if err != nil {
		return nil, err
	}

	return &pb.AdminResponse{
		Admin: &pb.Admin{
			Id:        admin.ID,
			UserId:    admin.UserID,
			Role:      admin.Role,
			CreatedAt: admin.CreatedAt.Format(time.RFC3339),
		},
	}, nil
}

// GetAllAdmins handles gRPC GetAllAdmins request
func (s *AdminGrpcServer) GetAllAdmins(ctx context.Context, req *pb.GetAllAdminsRequest) (*pb.AdminListResponse, error) {
	admins, err := s.service.GetAllAdmins()
	if err != nil {
		return nil, err
	}

	var result []*pb.Admin
	for _, a := range admins {
		result = append(result, &pb.Admin{
			Id:        a.ID,
			UserId:    a.UserID,
			Role:      a.Role,
			CreatedAt: a.CreatedAt.Format(time.RFC3339),
		})
	}

	return &pb.AdminListResponse{Admins: result}, nil
}

// IsAdmin handles gRPC IsAdmin request
func (s *AdminGrpcServer) IsAdmin(ctx context.Context, req *pb.IsAdminRequest) (*pb.IsAdminResponse, error) {
	isAdmin, err := s.service.IsAdmin(req.UserId)
	if err != nil {
		return nil, err
	}
	return &pb.IsAdminResponse{IsAdmin: isAdmin}, nil
}

// RemoveAdmin handles gRPC RemoveAdmin request
func (s *AdminGrpcServer) RemoveAdmin(ctx context.Context, req *pb.RemoveAdminRequest) (*pb.RemoveAdminResponse, error) {
	err := s.service.RemoveAdmin(req.Id)
	if err != nil {
		return nil, err
	}
	return &pb.RemoveAdminResponse{Message: "admin removed successfully"}, nil
}

// GetStats handles gRPC GetStats request
func (s *AdminGrpcServer) GetStats(ctx context.Context, req *pb.GetStatsRequest) (*pb.StatsResponse, error) {
	stats, err := s.service.GetSystemStats()
	if err != nil {
		return nil, err
	}

	return &pb.StatsResponse{
		TotalUsers:         int32(stats.TotalUsers),
		TotalRoutes:        int32(stats.TotalRoutes),
		TotalFeedbacks:     int32(stats.TotalFeedbacks),
		TotalNotifications: int32(stats.TotalNotifications),
	}, nil
}
