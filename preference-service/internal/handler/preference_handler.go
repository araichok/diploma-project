package handler

import (
	"context"

	"preference-service/internal/model"
	"preference-service/internal/service"
	pb "preference-service/proto/preferencepb"
)

type PreferenceHandler struct {
	pb.UnimplementedPreferenceServiceServer
	service *service.PreferenceService
}

func NewPreferenceHandler(service *service.PreferenceService) *PreferenceHandler {
	return &PreferenceHandler{service: service}
}

func modelToProto(p *model.Preference) *pb.Preference {
	return &pb.Preference{
		Id:         p.ID,
		UserId:     p.UserID,
		Mood:       p.Mood,
		Budget:     p.Budget,
		Duration:   p.Duration,
		Location:   p.Location,
		TravelDate: p.TravelDate,
		CreatedAt:  p.CreatedAt.String(),
	}
}

func (h *PreferenceHandler) CreatePreference(
	ctx context.Context,
	req *pb.CreatePreferenceRequest,
) (*pb.PreferenceResponse, error) {

	p := &model.Preference{
		UserID:     req.UserId,
		Mood:       req.Mood,
		Budget:     req.Budget,
		Duration:   req.Duration,
		Location:   req.Location,
		TravelDate: req.TravelDate,
	}

	created, err := h.service.CreatePreference(p)
	if err != nil {
		return nil, err
	}

	return &pb.PreferenceResponse{
		Preference: modelToProto(created),
	}, nil
}

func (h *PreferenceHandler) GetPreferenceHistory(
	ctx context.Context,
	req *pb.GetPreferenceHistoryRequest,
) (*pb.PreferenceHistoryResponse, error) {

	preferences, err := h.service.GetPreferenceHistory(req.UserId)
	if err != nil {
		return nil, err
	}

	var result []*pb.Preference

	for _, p := range preferences {
		result = append(result, modelToProto(p))
	}

	return &pb.PreferenceHistoryResponse{
		Preferences: result,
	}, nil
}

func (h *PreferenceHandler) UpdatePreference(
	ctx context.Context,
	req *pb.UpdatePreferenceRequest,
) (*pb.PreferenceResponse, error) {

	p := &model.Preference{
		ID:         req.Id,
		UserID:     req.UserId,
		Mood:       req.Mood,
		Budget:     req.Budget,
		Duration:   req.Duration,
		Location:   req.Location,
		TravelDate: req.TravelDate,
	}

	updated, err := h.service.UpdatePreference(p)
	if err != nil {
		return nil, err
	}

	return &pb.PreferenceResponse{
		Preference: modelToProto(updated),
	}, nil
}

func (h *PreferenceHandler) DeletePreference(
	ctx context.Context,
	req *pb.DeletePreferenceRequest,
) (*pb.DeletePreferenceResponse, error) {

	err := h.service.DeletePreference(req.Id, req.UserId)
	if err != nil {
		return nil, err
	}

	return &pb.DeletePreferenceResponse{
		Message: "Preference deleted successfully",
	}, nil
}
