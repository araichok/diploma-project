package main

import (
	"context"
	"log"
	"net"
	"os"
	"time"

	"preference-service/internal/handler"
	"preference-service/internal/repository"
	"preference-service/internal/service"
	pb "preference-service/proto"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"google.golang.org/grpc"
)

func main() {

	// 🔌 Mongo URI (универсально)
	mongoURI := "mongodb://localhost:27017"
	if uri := os.Getenv("MONGO_URI"); uri != "" {
		mongoURI = uri
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}

	db := client.Database("tourism")

	// gRPC сервер
	lis, err := net.Listen("tcp", ":50052")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()

	// DI
	repo := repository.NewPreferenceRepository(db)
	service := service.NewPreferenceService()
	handler := handler.NewPreferenceHandler(service, repo)

	pb.RegisterPreferenceServiceServer(s, handler)

	log.Println("Preference Service running on port 50052")

	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
