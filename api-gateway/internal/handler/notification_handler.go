package handler

import (
	"net/http"

	notificationpb "api-gateway/proto/notificationpb"

	"github.com/gin-gonic/gin"
)

type NotificationHandler struct {
	client notificationpb.NotificationServiceClient
}

func NewNotificationHandler(client notificationpb.NotificationServiceClient) *NotificationHandler {
	return &NotificationHandler{
		client: client,
	}
}

func (h *NotificationHandler) GetUserNotifications(c *gin.Context) {
	userID := c.Param("user_id")

	res, err := h.client.GetUserNotifications(
		c,
		&notificationpb.GetUserNotificationsRequest{
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
