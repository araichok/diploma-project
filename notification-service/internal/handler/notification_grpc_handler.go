package handler

import (
	"context"
	"time"

	"notification-service/internal/service"
	pb "notification-service/proto"
	emptypb "google.golang.org/protobuf/types/known/emptypb"
)

// NotificationGrpcServer implements the gRPC server
type NotificationGrpcServer struct {
	pb.UnimplementedNotificationServiceServer
	service *service.NotificationService
}

// NewNotificationGrpcServer creates a new gRPC server
func NewNotificationGrpcServer(service *service.NotificationService) *NotificationGrpcServer {
	return &NotificationGrpcServer{service: service}
}

// SendNotification handles gRPC SendNotification request
func (s *NotificationGrpcServer) SendNotification(ctx context.Context, req *pb.SendNotificationRequest) (*pb.NotificationResponse, error) {
	notification, err := s.service.SendNotification(req.UserId, req.Message, req.Type)
	if err != nil {
		return nil, err
	}

	return &pb.NotificationResponse{
		Notification: &pb.Notification{
			Id:        notification.ID,
			UserId:    notification.UserID,
			Message:   notification.Message,
			Type:      notification.Type,
			IsRead:    notification.IsRead,
			CreatedAt: notification.CreatedAt.Format(time.RFC3339),
		},
	}, nil
}

// GetUserNotifications handles gRPC GetUserNotifications request
func (s *NotificationGrpcServer) GetUserNotifications(ctx context.Context, req *pb.GetUserNotificationsRequest) (*pb.NotificationListResponse, error) {
	notifications, err := s.service.GetUserNotifications(req.UserId)
	if err != nil {
		return nil, err
	}

	var result []*pb.Notification
	for _, n := range notifications {
		result = append(result, &pb.Notification{
			Id:        n.ID,
			UserId:    n.UserID,
			Message:   n.Message,
			Type:      n.Type,
			IsRead:    n.IsRead,
			CreatedAt: n.CreatedAt.Format(time.RFC3339),
		})
	}

	return &pb.NotificationListResponse{Notifications: result}, nil
}

// MarkAsRead handles gRPC MarkAsRead request
func (s *NotificationGrpcServer) MarkAsRead(ctx context.Context, req *pb.MarkAsReadRequest) (*pb.NotificationResponse, error) {
	err := s.service.MarkAsRead(req.Id)
	if err != nil {
		return nil, err
	}
	return &pb.NotificationResponse{}, nil
}

// GetAllNotifications handles gRPC GetAllNotifications request (admin use)
func (s *NotificationGrpcServer) GetAllNotifications(ctx context.Context, _ *emptypb.Empty) (*pb.NotificationListResponse, error) {
	notifications, err := s.service.GetAllNotifications()
	if err != nil {
		return nil, err
	}
	var result []*pb.Notification
	for _, n := range notifications {
		result = append(result, &pb.Notification{
			Id:        n.ID,
			UserId:    n.UserID,
			Message:   n.Message,
			Type:      n.Type,
			IsRead:    n.IsRead,
			CreatedAt: n.CreatedAt.Format(time.RFC3339),
		})
	}
	return &pb.NotificationListResponse{Notifications: result}, nil
}

// GetUnreadCount handles gRPC GetUnreadCount request
func (s *NotificationGrpcServer) GetUnreadCount(ctx context.Context, req *pb.GetUnreadCountRequest) (*pb.UnreadCountResponse, error) {
	count, err := s.service.GetUnreadCount(req.UserId)
	if err != nil {
		return nil, err
	}
	return &pb.UnreadCountResponse{UnreadCount: int32(count)}, nil
}
