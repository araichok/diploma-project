package main

import (
	"log"
	"net"

	"google.golang.org/grpc"

	"location-service/internal/handler"
	"location-service/internal/repository"
	"location-service/internal/service"
	pb "location-service/location-service/proto"
)

func main() {

	db := repository.ConnectMongo("mongodb://mongo:27017")

	repo := repository.NewMongoRepository(db)

	locationService := service.NewLocationService(repo)

	locationHandler := handler.NewLocationHandler(locationService)

	listener, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}

	grpcServer := grpc.NewServer()

	pb.RegisterLocationServiceServer(grpcServer, locationHandler)

	log.Println("Location service running on port 50051")

	err = grpcServer.Serve(listener)
	if err != nil {
		log.Fatal(err)
	}
}
