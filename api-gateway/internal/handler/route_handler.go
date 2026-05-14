package handler

import (
	"context"
	"net/http"

	"api-gateway/proto/routepb"

	"github.com/gin-gonic/gin"
)

type RouteHandler struct {
	routeClient routepb.RouteServiceClient
}

func NewRouteHandler(routeClient routepb.RouteServiceClient) *RouteHandler {
	return &RouteHandler{
		routeClient: routeClient,
	}
}

func (h *RouteHandler) GetUserRoutes(c *gin.Context) {
	userID := c.Param("user_id")

	res, err := h.routeClient.GetUserRoutes(
		context.Background(),
		&routepb.GetUserRoutesRequest{
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

func (h *RouteHandler) GetRouteByID(c *gin.Context) {
	routeID := c.Param("route_id")

	res, err := h.routeClient.GetRouteByID(
		context.Background(),
		&routepb.GetRouteByIDRequest{
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
