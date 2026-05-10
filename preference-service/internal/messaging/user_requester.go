package messaging

import (
	"encoding/json"
	"errors"
	"log"
	"os"
	"time"

	"github.com/nats-io/nats.go"
)

type UserNATSClient struct {
	nc *nats.Conn
}

type UserCheckRequest struct {
	UserID string `json:"user_id"`
}

type UserCheckResponse struct {
	Exists bool   `json:"exists"`
	Error  string `json:"error,omitempty"`
}

func NewUserNATSClient() (*UserNATSClient, error) {
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = nats.DefaultURL
	}

	nc, err := nats.Connect(natsURL)
	if err != nil {
		return nil, err
	}

	return &UserNATSClient{
		nc: nc,
	}, nil
}

func (c *UserNATSClient) CheckUserExists(userID string) error {

	log.Println("[NATS] Sending user.check request for user_id:", userID)

	req := UserCheckRequest{
		UserID: userID,
	}

	data, err := json.Marshal(req)
	if err != nil {

		log.Println("[NATS] Failed to marshal request:", err)

		return err
	}

	msg, err := c.nc.Request("user.check", data, 5*time.Second)
	if err != nil {

		log.Println("[NATS] user.check request failed:", err)

		return err
	}

	var res UserCheckResponse

	err = json.Unmarshal(msg.Data, &res)
	if err != nil {

		log.Println("[NATS] Failed to unmarshal response:", err)

		return err
	}

	log.Println("[NATS] Received user.check response. exists:", res.Exists)

	if res.Error != "" {

		log.Println("[NATS] User service returned error:", res.Error)

		return errors.New(res.Error)
	}

	if !res.Exists {

		log.Println("[NATS] User not found:", userID)

		return errors.New("user not found")
	}

	log.Println("[NATS] User verified successfully:", userID)

	return nil
}
