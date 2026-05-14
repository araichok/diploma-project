package handler

import (
	"context"
	"net/http"

	"api-gateway/proto/userpb"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	userClient userpb.UserServiceClient
}

func NewUserHandler(userClient userpb.UserServiceClient) *UserHandler {
	return &UserHandler{
		userClient: userClient,
	}
}

func (h *UserHandler) Register(c *gin.Context) {
	var req userpb.RegisterRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	res, err := h.userClient.Register(
		context.Background(),
		&req,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *UserHandler) Login(c *gin.Context) {
	var req userpb.LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	res, err := h.userClient.Login(
		context.Background(),
		&req,
	)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, res)
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	userID := c.Param("id")

	res, err := h.userClient.GetProfile(
		context.Background(),
		&userpb.GetProfileRequest{
			Id: userID,
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
