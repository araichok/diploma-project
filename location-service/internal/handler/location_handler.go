package handler

import (
	"context"

	"github.com/google/uuid"

	"location-service/internal/model"
	"location-service/internal/service"
	pb "location-service/location-service/proto"
)

type LocationHandler struct {
	pb.UnimplementedLocationServiceServer
	service *service.LocationService
}

func NewLocationHandler(service *service.LocationService) *LocationHandler {
	return &LocationHandler{service: service}
}

func (h *LocationHandler) CreateLocation(ctx context.Context, req *pb.CreateLocationRequest) (*pb.LocationResponse, error) {

	location := &model.Location{
		ID:          uuid.New().String(),
		Name:        req.Name,
		Description: req.Description,
		City:        req.City,
		Category:    req.Category,
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
		Rating:      req.Rating,
	}

	err := h.service.CreateLocation(location)
	if err != nil {
		return nil, err
	}

	return &pb.LocationResponse{
		Location: &pb.Location{
			Id:          location.ID,
			Name:        location.Name,
			Description: location.Description,
			City:        location.City,
			Category:    location.Category,
			Latitude:    location.Latitude,
			Longitude:   location.Longitude,
			Rating:      location.Rating,
		},
	}, nil
}

func (h *LocationHandler) ListLocations(ctx context.Context, req *pb.Empty) (*pb.LocationList, error) {

	locations, err := h.service.ListLocations()
	if err != nil {
		return nil, err
	}

	var result []*pb.Location

	for _, loc := range locations {

		result = append(result, &pb.Location{
			Id:          loc.ID,
			Name:        loc.Name,
			Description: loc.Description,
			City:        loc.City,
			Category:    loc.Category,
			Latitude:    loc.Latitude,
			Longitude:   loc.Longitude,
			Rating:      loc.Rating,
		})
	}

	return &pb.LocationList{Locations: result}, nil
}

func (h *LocationHandler) SearchLocations(ctx context.Context, req *pb.SearchRequest) (*pb.LocationList, error) {

	locations, err := h.service.SearchLocations(req.City, req.Category, req.MinRating)
	if err != nil {
		return nil, err
	}

	var result []*pb.Location

	for _, loc := range locations {

		result = append(result, &pb.Location{
			Id:          loc.ID,
			Name:        loc.Name,
			Description: loc.Description,
			City:        loc.City,
			Category:    loc.Category,
			Latitude:    loc.Latitude,
			Longitude:   loc.Longitude,
			Rating:      loc.Rating,
		})
	}

	return &pb.LocationList{Locations: result}, nil
}
