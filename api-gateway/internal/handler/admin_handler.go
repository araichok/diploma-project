package handler

import (
	"net/http"

	adminpb "api-gateway/proto/adminpb"
	feedbackpb "api-gateway/proto/feedbackpb"
	notificationpb "api-gateway/proto/notificationpb"
	userpb "api-gateway/proto/userpb"

	"github.com/gin-gonic/gin"
	emptypb "google.golang.org/protobuf/types/known/emptypb"

	historypb "api-gateway/proto/historypb"
)

type AdminHandler struct {
	client         adminpb.AdminServiceClient
	feedbackClient feedbackpb.FeedbackServiceClient
	notifClient    notificationpb.NotificationServiceClient
	userClient     userpb.UserServiceClient
	historyClient historypb.RouteHistoryServiceClient
}

func NewAdminHandler(
	client adminpb.AdminServiceClient,
	feedbackClient feedbackpb.FeedbackServiceClient,
	notifClient notificationpb.NotificationServiceClient,
	userClient userpb.UserServiceClient,
	historyClient historypb.RouteHistoryServiceClient,
) *AdminHandler {
	return &AdminHandler{
		client:         client,
		feedbackClient: feedbackClient,
		notifClient:    notifClient,
		userClient:     userClient,
		historyClient: historyClient,
	}
}

func (h *AdminHandler) AddAdmin(c *gin.Context) {
	var req adminpb.AddAdminRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	res, err := h.client.AddAdmin(c, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *AdminHandler) IsAdmin(c *gin.Context) {
	userID := c.Param("user_id")

	res, err := h.client.IsAdmin(
		c,
		&adminpb.IsAdminRequest{
			UserId: userID,
		},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *AdminHandler) GetStats(c *gin.Context) {
	empty := &emptypb.Empty{}

	var userCount, routeCount, feedbackCount, notifCount int32

	if res, err := h.userClient.CountUsers(c, &userpb.CountUsersRequest{}); err == nil && res != nil {
		userCount = res.TotalUsers
	}

	if res, err := h.historyClient.CountRoutes(c, &historypb.CountRoutesRequest{}); err == nil && res != nil {
	routeCount = res.TotalRoutes
}

	if res, err := h.feedbackClient.GetAllFeedbacks(c, empty); err == nil && res != nil {
		feedbackCount = int32(len(res.Feedbacks))
	}

	if res, err := h.notifClient.GetAllNotifications(c, empty); err == nil && res != nil {
		notifCount = int32(len(res.Notifications))
	}

	c.JSON(http.StatusOK, gin.H{
		"total_users":         userCount,
		"total_routes":        routeCount,
		"total_feedbacks":     feedbackCount,
		"total_notifications": notifCount,
	})
}
func (h *AdminHandler) GetAllFeedbacks(c *gin.Context) {
	res, err := h.feedbackClient.GetAllFeedbacks(c, &emptypb.Empty{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}

func (h *AdminHandler) GetAllNotifications(c *gin.Context) {
	res, err := h.notifClient.GetAllNotifications(c, &emptypb.Empty{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}
