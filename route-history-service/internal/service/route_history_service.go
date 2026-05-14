package service

import (
	"context"
	"log"

	"route-history-service/internal/client"
	"route-history-service/internal/repository"
	"route-history-service/models"
	pb "route-history-service/proto"
)

type RouteHistoryService struct {
	pb.UnimplementedRouteHistoryServiceServer
	repo                  *repository.RouteHistoryRepository
	notificationClient    *client.NotificationClient
	routeGenerationClient *client.RouteGenerationClient
}

func NewRouteHistoryService(repo *repository.RouteHistoryRepository) *RouteHistoryService {
	return &RouteHistoryService{
		repo:                  repo,
		notificationClient:    client.NewNotificationClient(),
		routeGenerationClient: client.NewRouteGenerationClient(),
	}
}

func (s *RouteHistoryService) CreateHistory(ctx context.Context, req *pb.CreateHistoryRequest) (*pb.HistoryResponse, error) {
	history := &models.RouteHistory{
		UserID:    req.UserId,
		RouteID:   req.RouteId,
		RouteName: req.RouteName,
		Mood:      req.Mood,
	}

	route, err := s.routeGenerationClient.GetRouteByID(req.RouteId)
	if err == nil && route != nil {
		history.RouteName = route.Title
		history.Mood = route.Mood
		log.Printf("Got route details: %s, mood: %s", route.Title, route.Mood)
	}

	err = s.repo.Create(history)
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

func (s *RouteHistoryService) UpdateHistoryStatus(ctx context.Context, req *pb.UpdateHistoryStatusRequest) (*pb.HistoryResponse, error) {

	err := s.repo.UpdateStatus(req.RouteId, req.Status)
	if err != nil {
		return nil, err
	}

	history, err := s.repo.GetByRouteID(req.RouteId)
	if err != nil {
		return nil, err
	}

	if req.Status == "planned" {
		go s.notificationClient.SendNotification(
			history.UserID,
			"You have a planned trip.",
			"route_planned",
		)
	}

	if req.Status == "completed" {
		go s.notificationClient.SendNotification(
			history.UserID,
			"Your route has been completed! Please leave feedback.",
			"route_completed",
		)
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

func (s *RouteHistoryService) CheckRouteCompleted(
	ctx context.Context,
	req *pb.CheckRouteCompletedRequest,
) (*pb.CheckRouteCompletedResponse, error) {

	history, err := s.repo.GetByRouteID(req.RouteId)
	if err != nil {
		return nil, err
	}

	isCompleted := history.Status == "completed"

	return &pb.CheckRouteCompletedResponse{
		IsCompleted: isCompleted,
		Status:      history.Status,
	}, nil
}
