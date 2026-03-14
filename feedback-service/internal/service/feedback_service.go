package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"feedback-service/internal/client"
	pb "feedback-service/proto"
)

type FeedbackServer struct {
	pb.UnimplementedFeedbackServiceServer
	feedbacks     []*pb.Feedback
	historyClient *client.HistoryClient
}

func NewFeedbackServer() *FeedbackServer {
	return &FeedbackServer{
		feedbacks:     []*pb.Feedback{},
		historyClient: client.NewHistoryClient(),
	}
}

func (s *FeedbackServer) CreateFeedback(ctx context.Context, req *pb.CreateFeedbackRequest) (*pb.FeedbackResponse, error) {
	feedback := &pb.Feedback{
		FeedbackId: uuid.New().String(),
		UserId:     req.UserId,
		RouteId:    req.RouteId,
		Rating:     req.Rating,
		Review:     req.Review,
		CreatedAt:  time.Now().Format(time.RFC3339),
	}

	s.feedbacks = append(s.feedbacks, feedback)

	s.historyClient.UpdateStatus(req.RouteId, "completed")

	return &pb.FeedbackResponse{
		Feedback: feedback,
	}, nil
}

func (s *FeedbackServer) GetFeedbackByRoute(ctx context.Context, req *pb.GetFeedbackByRouteRequest) (*pb.FeedbackListResponse, error) {
	var result []*pb.Feedback

	for _, feedback := range s.feedbacks {
		if feedback.RouteId == req.RouteId {
			result = append(result, feedback)
		}
	}

	return &pb.FeedbackListResponse{
		Feedbacks: result,
	}, nil
}

func (s *FeedbackServer) GetFeedbackByUser(ctx context.Context, req *pb.GetFeedbackByUserRequest) (*pb.FeedbackListResponse, error) {
	var result []*pb.Feedback

	for _, feedback := range s.feedbacks {
		if feedback.UserId == req.UserId {
			result = append(result, feedback)
		}
	}

	return &pb.FeedbackListResponse{
		Feedbacks: result,
	}, nil
}
