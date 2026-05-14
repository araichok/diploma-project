package handler

import (
	"net/http"

	adminpb "api-gateway/proto/adminpb"

	"github.com/gin-gonic/gin"
)

type AdminHandler struct {
	client adminpb.AdminServiceClient
}

func NewAdminHandler(client adminpb.AdminServiceClient) *AdminHandler {
	return &AdminHandler{
		client: client,
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
	res, err := h.client.GetStats(
		c,
		&adminpb.GetStatsRequest{},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}
