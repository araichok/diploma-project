package router

import (
	"api-gateway/internal/handler"
	"api-gateway/internal/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter(
	userHandler *handler.UserHandler,
	preferenceHandler *handler.PreferenceHandler,
	routeHandler *handler.RouteHandler,
) *gin.Engine {

	r := gin.Default()

	api := r.Group("/api/v1")

	// public routes
	api.POST("/register", userHandler.Register)
	api.POST("/login", userHandler.Login)

	// protected routes
	protected := api.Group("/")
	protected.Use(middleware.AuthMiddleware())

	// user
	protected.GET("/profile/:id", userHandler.GetProfile)

	// preferences
	protected.POST("/preferences", preferenceHandler.CreatePreference)

	protected.GET(
		"/preferences/history/:user_id",
		preferenceHandler.GetPreferenceHistory,
	)

	protected.DELETE(
		"/preferences/:id/:user_id",
		preferenceHandler.DeletePreference,
	)

	// routes
	protected.GET(
		"/routes/:user_id",
		routeHandler.GetUserRoutes,
	)

	protected.GET(
		"/route/:route_id",
		routeHandler.GetRouteByID,
	)

	return r
}
