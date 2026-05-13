package handler

import (
	"context"

	"route-generation-service/internal/model"
	"route-generation-service/internal/service"
	routepb "route-generation-service/proto/routepb"
)

type RouteGrpcHandler struct {
	routepb.UnimplementedRouteServiceServer
	routeService *service.RouteService
}

func NewRouteGrpcHandler(routeService *service.RouteService) *RouteGrpcHandler {
	return &RouteGrpcHandler{
		routeService: routeService,
	}
}

func (h *RouteGrpcHandler) GetRouteByID(
	ctx context.Context,
	req *routepb.GetRouteByIDRequest,
) (*routepb.RouteResponse, error) {
	route, err := h.routeService.GetRouteByID(ctx, req.RouteId)
	if err != nil {
		return nil, err
	}

	return &routepb.RouteResponse{
		Route: mapRouteToProto(route),
	}, nil
}

func (h *RouteGrpcHandler) GetUserRoutes(
	ctx context.Context,
	req *routepb.GetUserRoutesRequest,
) (*routepb.GetUserRoutesResponse, error) {
	routes, err := h.routeService.GetUserRoutes(ctx, req.UserId)
	if err != nil {
		return nil, err
	}

	var protoRoutes []*routepb.Route

	for i := range routes {
		protoRoutes = append(protoRoutes, mapRouteToProto(&routes[i]))
	}

	return &routepb.GetUserRoutesResponse{
		Routes: protoRoutes,
	}, nil
}

func mapRouteToProto(route *model.Route) *routepb.Route {
	var places []*routepb.RoutePlace

	for _, place := range route.Places {
		places = append(places, &routepb.RoutePlace{
			Id:            place.ID,
			RouteId:       place.RouteID,
			PlaceId:       place.PlaceID,
			Name:          place.Name,
			Type:          place.Type,
			Address:       place.Address,
			Lat:           place.Lat,
			Lon:           place.Lon,
			VisitOrder:    place.VisitOrder,
			EstimatedTime: place.EstimatedTime,
			EstimatedCost: place.EstimatedCost,
		})
	}

	return &routepb.Route{
		Id:            route.ID,
		UserId:        route.UserID,
		PreferenceId:  route.PreferenceID,
		Title:         route.Title,
		Mood:          route.Mood,
		City:          route.City,
		TotalBudget:   route.TotalBudget,
		TotalDuration: route.TotalDuration,
		CreatedAt:     route.CreatedAt.Format("2006-01-02 15:04:05"),
		Places:        places,
	}
}
