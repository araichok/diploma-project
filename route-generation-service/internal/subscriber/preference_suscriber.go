package subscriber

import (
	"context"
	"encoding/json"
	"log"

	"route-generation-service/internal/service"

	"github.com/nats-io/nats.go"
)

type PreferenceSubscriber struct {
	natsConn     *nats.Conn
	routeService *service.RouteService
}

func NewPreferenceSubscriber(
	natsConn *nats.Conn,
	routeService *service.RouteService,
) *PreferenceSubscriber {
	return &PreferenceSubscriber{
		natsConn:     natsConn,
		routeService: routeService,
	}
}

func (s *PreferenceSubscriber) SubscribePreferenceCreated() error {
	_, err := s.natsConn.Subscribe("preference.created", func(msg *nats.Msg) {
		var event service.PreferenceCreatedEvent

		err := json.Unmarshal(msg.Data, &event)
		if err != nil {
			log.Println("failed to unmarshal preference.created event:", err)
			return
		}

		log.Println("received preference.created event:", event.PreferenceID)

		route, err := s.routeService.GenerateRouteFromPreference(context.Background(), event)
		if err != nil {
			log.Println("failed to generate route:", err)
			return
		}

		log.Println("route generated successfully:", route.ID)
	})

	if err != nil {
		return err
	}

	log.Println("subscribed to NATS subject: preference.created")
	return nil
}
