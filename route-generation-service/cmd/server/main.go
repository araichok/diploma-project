package main

import (
	"log"
	"net"

	"route-generation-service/internal/client"
	"route-generation-service/internal/config"
	"route-generation-service/internal/db"
	"route-generation-service/internal/handler"
	"route-generation-service/internal/repository"
	"route-generation-service/internal/service"
	"route-generation-service/internal/subscriber"
	routepb "route-generation-service/proto/routepb"

	"github.com/nats-io/nats.go"
	"google.golang.org/grpc"
)

func main() {
	cfg := config.LoadConfig()

	postgresDB, err := db.ConnectPostgres(cfg)
	if err != nil {
		log.Fatal("failed to connect PostgreSQL:", err)
	}
	defer postgresDB.Close()

	log.Println("connected to PostgreSQL")

	natsConn, err := nats.Connect(cfg.NatsURL)
	if err != nil {
		log.Fatal("failed to connect NATS:", err)
	}
	defer natsConn.Close()

	log.Println("connected to NATS")

	locationClient, err := client.NewLocationClient(cfg.LocationServiceAddr)
	if err != nil {
		log.Fatal("failed to connect location-service:", err)
	}
	defer locationClient.Close()

	log.Println("connected to location-service:", cfg.LocationServiceAddr)

	routeRepo := repository.NewRouteRepository(postgresDB)
	routeService := service.NewRouteService(routeRepo, locationClient)

	preferenceSubscriber := subscriber.NewPreferenceSubscriber(natsConn, routeService)
	if err := preferenceSubscriber.SubscribePreferenceCreated(); err != nil {
		log.Fatal("failed to subscribe to preference.created:", err)
	}

	grpcServer := grpc.NewServer()
	routeHandler := handler.NewRouteGrpcHandler(routeService)

	routepb.RegisterRouteServiceServer(grpcServer, routeHandler)

	listener, err := net.Listen("tcp", ":"+cfg.GRPCPort)
	if err != nil {
		log.Fatal("failed to listen:", err)
	}

	log.Println("route-generation-service started on port:", cfg.GRPCPort)

	if err := grpcServer.Serve(listener); err != nil {
		log.Fatal("failed to serve grpc:", err)
	}
}
