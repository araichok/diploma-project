package main

import (
	"fmt"
	"log"
	"net/http"

	"notification-service/internal/database"
	"notification-service/internal/handler"
	"notification-service/internal/repository"
	"notification-service/internal/service"
)

func main() {
	db := database.Connect()
	defer db.Close()

	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS notifications (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL,
			message TEXT NOT NULL,
			type VARCHAR(50) NOT NULL,
			is_read BOOLEAN DEFAULT FALSE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	`)
	if err != nil {
		log.Fatalf("failed to create table: %v", err)
	}

	repo := repository.NewNotificationRepository(db)
	svc := service.NewNotificationService(repo)
	h := handler.NewNotificationHandler(svc)

	http.HandleFunc("/notifications", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			h.SendNotification(w, r)
		} else if r.Method == http.MethodGet {
			h.GetUserNotifications(w, r)
		}
	})

	http.HandleFunc("/notifications/read", h.MarkAsRead)
	http.HandleFunc("/notifications/read-all", h.MarkAllAsRead)
	http.HandleFunc("/notifications/unread-count", h.GetUnreadCount)

	fmt.Println("Notification Service running on port 50057")
	log.Fatal(http.ListenAndServe(":50057", nil))
}
