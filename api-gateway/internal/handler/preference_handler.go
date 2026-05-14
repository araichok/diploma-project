package handler

import (
	"context"
	"net/http"

	"api-gateway/proto/preferencepb"

	"github.com/gin-gonic/gin"
)

type PreferenceHandler struct {
	preferenceClient preferencepb.PreferenceServiceClient
}

func NewPreferenceHandler(
	preferenceClient preferencepb.PreferenceServiceClient,
) *PreferenceHandler {
	return &PreferenceHandler{
		preferenceClient: preferenceClient,
	}
}

func (h *PreferenceHandler) CreatePreference(c *gin.Context) {
	var req preferencepb.CreatePreferenceRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	res, err := h.preferenceClient.CreatePreference(
		context.Background(),
		&req,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "Preference created. Route generation started.",
		"preference": res.Preference,
	})
}

func (h *PreferenceHandler) GetPreferenceHistory(c *gin.Context) {
	userID := c.Param("user_id")

	res, err := h.preferenceClient.GetPreferenceHistory(
		context.Background(),
		&preferencepb.GetPreferenceHistoryRequest{
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

func (h *PreferenceHandler) DeletePreference(c *gin.Context) {
	id := c.Param("id")
	userID := c.Param("user_id")

	res, err := h.preferenceClient.DeletePreference(
		context.Background(),
		&preferencepb.DeletePreferenceRequest{
			Id:     id,
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
