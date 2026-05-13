package messaging

import (
	"encoding/json"
	"log"
)

type PreferenceCreatedEvent struct {
	PreferenceID string  `json:"preference_id"`
	UserID       string  `json:"user_id"`
	Mood         string  `json:"mood"`
	Date         string  `json:"date"`
	Budget       float64 `json:"budget"`
	Duration     int32   `json:"duration"`
	Location     string  `json:"location"`
}

func (c *UserNATSClient) PublishPreferenceCreated(event PreferenceCreatedEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return err
	}

	err = c.nc.Publish("preference.created", data)
	if err != nil {
		return err
	}

	log.Println("[NATS] preference.created event published")

	return nil
}
