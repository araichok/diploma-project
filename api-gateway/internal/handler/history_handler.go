package handler

import (
	"net/http"

	historypb "api-gateway/proto/historypb"

	"github.com/gin-gonic/gin"
)

type HistoryHandler struct {
	client historypb.RouteHistoryServiceClient
}

func NewHistoryHandler(client historypb.RouteHistoryServiceClient) *HistoryHandler {
	return &HistoryHandler{
		client: client,
	}
}

func (h *HistoryHandler) GetUserHistory(c *gin.Context) {
	userID := c.Param("user_id")

	res, err := h.client.GetUserHistory(
		c,
		&historypb.GetUserHistoryRequest{
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
