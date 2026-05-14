package service

import (
	"context"

	"route-history-service/internal/client"
	"route-history-service/internal/repository"
	"route-history-service/models"
	pb "route-history-service/proto"
)

// RouteHistoryService handles business logic for route history
type RouteHistoryService struct {
	pb.UnimplementedRouteHistoryServiceServer
	repo               *repository.RouteHistoryRepository
	notificationClient *client.NotificationClient
}

func NewRouteHistoryService(repo *repository.RouteHistoryRepository) *RouteHistoryService {
	return &RouteHistoryService{
		repo:               repo,
		notificationClient: client.NewNotificationClient(),
	}
}

// CreateHistory saves a new route history entry via gRPC
func (s *RouteHistoryService) CreateHistory(ctx context.Context, req *pb.CreateHistoryRequest) (*pb.HistoryResponse, error) {
	history := &models.RouteHistory{
		UserID:    req.UserId,
		RouteID:   req.RouteId,
		RouteName: req.RouteName,
		Mood:      req.Mood,
	}

	err := s.repo.Create(history)
	if err != nil {
		return nil, err
	}

	return &pb.HistoryResponse{
		History: &pb.History{
			HistoryId: history.ID,
			UserId:    history.UserID,
			RouteId:   history.RouteID,
			RouteName: history.RouteName,
			Mood:      history.Mood,
			Status:    history.Status,
			CreatedAt: history.CreatedAt.String(),
		},
	}, nil
}

// GetUserHistory returns all history for a user via gRPC
func (s *RouteHistoryService) GetUserHistory(ctx context.Context, req *pb.GetUserHistoryRequest) (*pb.HistoryListResponse, error) {
	histories, err := s.repo.GetByUserID(req.UserId)
	if err != nil {
		return nil, err
	}

	var result []*pb.History
	for _, h := range histories {
		result = append(result, &pb.History{
			HistoryId: h.ID,
			UserId:    h.UserID,
			RouteId:   h.RouteID,
			RouteName: h.RouteName,
			Mood:      h.Mood,
			Status:    h.Status,
			CreatedAt: h.CreatedAt.String(),
		})
	}

	return &pb.HistoryListResponse{Histories: result}, nil
}

// GetHistoryById returns a single history entry via gRPC
func (s *RouteHistoryService) GetHistoryById(ctx context.Context, req *pb.GetHistoryByIdRequest) (*pb.HistoryResponse, error) {
	h, err := s.repo.GetByID(req.HistoryId)
	if err != nil {
		return nil, err
	}

	return &pb.HistoryResponse{
		History: &pb.History{
			HistoryId: h.ID,
			UserId:    h.UserID,
			RouteId:   h.RouteID,
			RouteName: h.RouteName,
			Mood:      h.Mood,
			Status:    h.Status,
			CreatedAt: h.CreatedAt.String(),
		},
	}, nil
}

// UpdateHistoryStatus updates the status of a route history entry via gRPC
func (s *RouteHistoryService) UpdateHistoryStatus(ctx context.Context, req *pb.UpdateHistoryStatusRequest) (*pb.HistoryResponse, error) {
	err := s.repo.UpdateStatus(req.RouteId, req.Status)
	if err != nil {
		return nil, err
	}

	// Send notification when route is completed
	if req.Status == "completed" {
		go s.notificationClient.SendNotification(
			req.RouteId,
			"Your route has been completed! Please leave feedback.",
			"route_completed",
		)
	}

	return &pb.HistoryResponse{}, nil
}
