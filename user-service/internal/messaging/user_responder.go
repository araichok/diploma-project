package messaging

import (
	"encoding/json"
	"log"
	"os"

	"github.com/nats-io/nats.go"
)

type UserRepository interface {
	ExistsByID(id string) (bool, error)
}

type UserCheckRequest struct {
	UserID string `json:"user_id"`
}

type UserCheckResponse struct {
	Exists bool   `json:"exists"`
	Error  string `json:"error,omitempty"`
}

func StartUserCheckSubscriber(repo UserRepository) error {
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = nats.DefaultURL
	}

	nc, err := nats.Connect(natsURL)
	if err != nil {
		return err
	}

	_, err = nc.Subscribe("user.check", func(msg *nats.Msg) {

		log.Println("[NATS] Received user.check request")

		var req UserCheckRequest

		if err := json.Unmarshal(msg.Data, &req); err != nil {

			log.Println("[NATS] Invalid request:", err)

			sendResponse(msg, UserCheckResponse{
				Exists: false,
				Error:  "invalid request",
			})
			return
		}

		log.Println("[NATS] Checking user_id:", req.UserID)

		exists, err := repo.ExistsByID(req.UserID)
		if err != nil {

			log.Println("[NATS] Error checking user:", err)

			sendResponse(msg, UserCheckResponse{
				Exists: false,
				Error:  err.Error(),
			})
			return
		}

		log.Println("[NATS] User exists:", exists)

		sendResponse(msg, UserCheckResponse{
			Exists: exists,
		})
	})

	if err != nil {
		return err
	}

	log.Println("NATS subscriber started: user.check")

	return nil
}

func sendResponse(msg *nats.Msg, res UserCheckResponse) {
	data, _ := json.Marshal(res)

	if msg.Reply != "" {
		_ = msg.Respond(data)
	}
}
