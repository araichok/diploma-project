package handler

import (
	"net/http"

	feedbackpb "api-gateway/proto/feedbackpb"

	"github.com/gin-gonic/gin"
)

type FeedbackHandler struct {
	client feedbackpb.FeedbackServiceClient
}

func NewFeedbackHandler(client feedbackpb.FeedbackServiceClient) *FeedbackHandler {
	return &FeedbackHandler{
		client: client,
	}
}

func (h *FeedbackHandler) CreateFeedback(c *gin.Context) {
	var req feedbackpb.CreateFeedbackRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	res, err := h.client.CreateFeedback(c, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *FeedbackHandler) GetFeedbackByRoute(c *gin.Context) {
	routeID := c.Param("route_id")

	res, err := h.client.GetFeedbackByRoute(
		c,
		&feedbackpb.GetFeedbackByRouteRequest{
			RouteId: routeID,
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
