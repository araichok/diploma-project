package main

import (
	"context"
	"log"
	"time"

	locationpb "location-service/proto/locationpb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {

	conn, err := grpc.NewClient(
		"localhost:50054",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	client := locationpb.NewLocationServiceClient(conn)

	ctx, cancel := context.WithTimeout(
		context.Background(),
		30*time.Second,
	)
	defer cancel()

	res, err := client.FindSuitableLocations(
		ctx,
		&locationpb.FindLocationsRequest{
			Mood:     "calm",
			Date:     "2026-05-11",
			Budget:   10000,
			Duration: 4,
			Location: "Astana",
		},
	)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Found locations:")

	for _, loc := range res.Locations {

		log.Printf(
			"PlaceID: %s | Name: %s | Type: %s | City: %s | Lat: %f | Lon: %f | Mood: %s",
			loc.PlaceId,
			loc.Name,
			loc.Type,
			loc.City,
			loc.Lat,
			loc.Lon,
			loc.Mood,
		)
	}

	if len(res.Locations) == 0 {
		log.Fatal("no locations found")
	}

	firstPlaceID := res.Locations[0].PlaceId

	details, err := client.GetLocationDetails(
		ctx,
		&locationpb.GetLocationDetailsRequest{
			PlaceId: firstPlaceID,
		},
	)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Location details:")

	log.Println("PlaceID:", details.PlaceId)
	log.Println("Name:", details.Name)
	log.Println("Address:", details.Address)
	log.Println("Website:", details.Website)
	log.Println("Phone:", details.Phone)
	log.Println("OpeningHours:", details.OpeningHours)
	log.Println("Description:", details.Description)
}
