package service

import (
	"context"
	"fmt"

	"feedback-service/internal/client"
	"feedback-service/internal/repository"
	"feedback-service/models"
	pb "feedback-service/proto"
)

// FeedbackService handles business logic for feedback
type FeedbackService struct {
	pb.UnimplementedFeedbackServiceServer
	repo               *repository.FeedbackRepository
	notificationClient *client.NotificationClient
	historyClient      *client.HistoryClient
}

// NewFeedbackService creates a new FeedbackService
func NewFeedbackService(repo *repository.FeedbackRepository) *FeedbackService {
	return &FeedbackService{
		repo:               repo,
		notificationClient: client.NewNotificationClient(),
		historyClient:      client.NewHistoryClient(),
	}
}

// CreateFeedback saves a new feedback via gRPC
func (s *FeedbackService) CreateFeedback(ctx context.Context, req *pb.CreateFeedbackRequest) (*pb.FeedbackResponse, error) {
	feedback := &models.Feedback{
		UserID:     req.UserId,
		RouteID:    req.RouteId,
		LocationID: req.LocationId,
		Rating:     int(req.Rating),
		Comment:    req.Comment,
	}

	completed, err := s.historyClient.CheckRouteCompleted(req.RouteId)
	if err != nil {
		return nil, err
	}

	if !completed {
		return nil, fmt.Errorf("feedback can only be added for completed routes")
	}

	err = s.repo.Create(feedback)
	if err != nil {
		return nil, err
	}

	// Send notification to user
	go s.notificationClient.SendNotification(
		req.UserId,
		"Your feedback has been submitted successfully!",
		"feedback_submitted",
	)

	return &pb.FeedbackResponse{
		Feedback: &pb.Feedback{
			FeedbackId: feedback.ID,
			UserId:     feedback.UserID,
			RouteId:    feedback.RouteID,
			LocationId: feedback.LocationID,
			Rating:     int32(feedback.Rating),
			Comment:    feedback.Comment,
			CreatedAt:  feedback.CreatedAt.String(),
		},
	}, nil
}

// GetFeedbackByRoute returns all feedbacks for a route via gRPC
func (s *FeedbackService) GetFeedbackByRoute(ctx context.Context, req *pb.GetFeedbackByRouteRequest) (*pb.FeedbackListResponse, error) {
	feedbacks, err := s.repo.GetByRouteID(req.RouteId)
	if err != nil {
		return nil, err
	}

	var result []*pb.Feedback
	for _, f := range feedbacks {
		result = append(result, &pb.Feedback{
			FeedbackId: f.ID,
			UserId:     f.UserID,
			RouteId:    f.RouteID,
			LocationId: f.LocationID,
			Rating:     int32(f.Rating),
			Comment:    f.Comment,
			CreatedAt:  f.CreatedAt.String(),
		})
	}

	return &pb.FeedbackListResponse{Feedbacks: result}, nil
}

// GetFeedbackByUser returns all feedbacks for a user via gRPC
func (s *FeedbackService) GetFeedbackByUser(ctx context.Context, req *pb.GetFeedbackByUserRequest) (*pb.FeedbackListResponse, error) {
	feedbacks, err := s.repo.GetByUserID(req.UserId)
	if err != nil {
		return nil, err
	}

	var result []*pb.Feedback
	for _, f := range feedbacks {
		result = append(result, &pb.Feedback{
			FeedbackId: f.ID,
			UserId:     f.UserID,
			RouteId:    f.RouteID,
			LocationId: f.LocationID,
			Rating:     int32(f.Rating),
			Comment:    f.Comment,
			CreatedAt:  f.CreatedAt.String(),
		})
	}

	return &pb.FeedbackListResponse{Feedbacks: result}, nil
}
