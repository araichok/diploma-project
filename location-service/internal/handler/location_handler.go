package handler

import (
	"context"

	"location-service/internal/service"
	locationpb "location-service/proto/locationpb"
)

type LocationGrpcHandler struct {
	locationpb.UnimplementedLocationServiceServer
	locationService *service.LocationService
}

func NewLocationGrpcHandler(locationService *service.LocationService) *LocationGrpcHandler {
	return &LocationGrpcHandler{
		locationService: locationService,
	}
}

func (h *LocationGrpcHandler) FindSuitableLocations(
	ctx context.Context,
	req *locationpb.FindLocationsRequest,
) (*locationpb.FindLocationsResponse, error) {

	locations, err := h.locationService.FindSuitableLocations(
		req.Mood,
		req.Location,
	)
	if err != nil {
		return nil, err
	}

	var result []*locationpb.Location

	for _, location := range locations {
		result = append(result, &locationpb.Location{
			PlaceId: location.PlaceID,
			Name:    location.Name,
			Type:    location.Type,
			Address: location.Address,
			City:    location.City,
			Lat:     location.Lat,
			Lon:     location.Lon,
			Mood:    location.Mood,
		})
	}

	return &locationpb.FindLocationsResponse{
		Locations: result,
	}, nil
}
