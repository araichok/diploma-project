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

	return h.locationService.FindSuitableLocations(
		ctx,
		req.Mood,
		req.Date,
		req.Budget,
		req.Duration,
		req.Location,
	)
}

func (h *LocationGrpcHandler) GetLocationDetails(
	ctx context.Context,
	req *locationpb.GetLocationDetailsRequest,
) (*locationpb.LocationDetailsResponse, error) {

	return h.locationService.GetLocationDetails(ctx, req.PlaceId)
}
