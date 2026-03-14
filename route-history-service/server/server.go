package server

import (
	"context"
	"time"

	"github.com/google/uuid"

	pb "route-history-service/proto"
)

type RouteHistoryServer struct {
	pb.UnimplementedRouteHistoryServiceServer
	histories []*pb.History
}

func NewRouteHistoryServer() *RouteHistoryServer {
	return &RouteHistoryServer{
		histories: []*pb.History{},
	}
}

func (s *RouteHistoryServer) CreateHistory(ctx context.Context, req *pb.CreateHistoryRequest) (*pb.HistoryResponse, error) {
	history := &pb.History{
		HistoryId: uuid.New().String(),
		UserId:    req.UserId,
		RouteId:   req.RouteId,
		RouteName: req.RouteName,
		Status:    "planned",
		CreatedAt: time.Now().Format(time.RFC3339),
	}

	s.histories = append(s.histories, history)

	return &pb.HistoryResponse{
		History: history,
	}, nil
}

func (s *RouteHistoryServer) GetUserHistory(ctx context.Context, req *pb.GetUserHistoryRequest) (*pb.HistoryListResponse, error) {
	var result []*pb.History

	for _, history := range s.histories {
		if history.UserId == req.UserId {
			result = append(result, history)
		}
	}

	return &pb.HistoryListResponse{
		Histories: result,
	}, nil
}

func (s *RouteHistoryServer) GetHistoryById(ctx context.Context, req *pb.GetHistoryByIdRequest) (*pb.HistoryResponse, error) {
	for _, history := range s.histories {
		if history.HistoryId == req.HistoryId {
			return &pb.HistoryResponse{
				History: history,
			}, nil
		}
	}

	return &pb.HistoryResponse{}, nil
}

func (s *RouteHistoryServer) UpdateHistoryStatus(ctx context.Context, req *pb.UpdateHistoryStatusRequest) (*pb.HistoryResponse, error) {
	for _, history := range s.histories {
		if history.RouteId == req.RouteId {
			history.Status = req.Status
			return &pb.HistoryResponse{
				History: history,
			}, nil
		}
	}

	return &pb.HistoryResponse{}, nil
}
