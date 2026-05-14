package main

import (
	"log"
	"os"

	"api-gateway/internal/client"
	"api-gateway/internal/handler"
	"api-gateway/internal/router"

	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	userClient, err := client.NewUserClient(os.Getenv("USER_SERVICE_ADDR"))
	if err != nil {
		log.Fatal("failed to connect user-service: ", err)
	}

	preferenceClient, err := client.NewPreferenceClient(os.Getenv("PREFERENCE_SERVICE_ADDR"))
	if err != nil {
		log.Fatal("failed to connect preference-service: ", err)
	}

	routeClient, err := client.NewRouteClient(os.Getenv("ROUTE_SERVICE_ADDR"))
	if err != nil {
		log.Fatal("failed to connect route-generation-service: ", err)
	}

	historyClient, err := client.NewHistoryClient(os.Getenv("HISTORY_SERVICE_ADDR"))
	if err != nil {
		log.Fatal("failed to connect route-history-service: ", err)
	}

	feedbackClient, err := client.NewFeedbackClient(os.Getenv("FEEDBACK_SERVICE_ADDR"))
	if err != nil {
		log.Fatal("failed to connect feedback-service: ", err)
	}

	userHandler := handler.NewUserHandler(userClient)
	preferenceHandler := handler.NewPreferenceHandler(preferenceClient)
	routeHandler := handler.NewRouteHandler(routeClient)
	historyHandler := handler.NewHistoryHandler(historyClient)
	feedbackHandler := handler.NewFeedbackHandler(feedbackClient)

	r := router.SetupRouter(
		userHandler,
		preferenceHandler,
		routeHandler,
		historyHandler,
		feedbackHandler,
	)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("API Gateway started on port:", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
