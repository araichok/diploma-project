package main

import (
	"fmt"
	"log"
	"net/http"

	"admin-service/internal/database"
	"admin-service/internal/handler"
	"admin-service/internal/repository"
	"admin-service/internal/service"
)

func main() {
	db := database.Connect()
	defer db.Close()

	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS admins (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL UNIQUE,
			role VARCHAR(50) NOT NULL DEFAULT 'admin',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);
	`)
	if err != nil {
		log.Fatalf("failed to create table: %v", err)
	}

	repo := repository.NewAdminRepository(db)
	svc := service.NewAdminService(repo)
	h := handler.NewAdminHandler(svc)

	http.HandleFunc("/admin/add", h.AddAdmin)
	http.HandleFunc("/admin/list", h.GetAllAdmins)
	http.HandleFunc("/admin/check", h.CheckAdmin)
	http.HandleFunc("/admin/remove", h.RemoveAdmin)
	http.HandleFunc("/admin/stats", h.GetStats)

	fmt.Println("Admin Service running on port 8084")
	log.Fatal(http.ListenAndServe(":8084", nil))
}
