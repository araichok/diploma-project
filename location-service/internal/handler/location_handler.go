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

func (h *LocationGrpcHandler) GetLocationDetails(
	ctx context.Context,
	req *locationpb.GetLocationDetailsRequest,
) (*locationpb.LocationDetailsResponse, error) {

	details, err := h.locationService.GetLocationDetails(req.PlaceId)
	if err != nil {
		return nil, err
	}

	return &locationpb.LocationDetailsResponse{
		PlaceId:      details.PlaceID,
		Name:         details.Name,
		Address:      details.Address,
		Website:      details.Website,
		Phone:        details.Phone,
		OpeningHours: details.OpeningHours,
		Description:  details.Description,
	}, nil
}
