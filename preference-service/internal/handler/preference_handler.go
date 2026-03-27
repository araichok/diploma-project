package handler

import (
	"context"

	"preference-service/internal/model"
	"preference-service/internal/repository"
	"preference-service/internal/service"
	pb "preference-service/proto"
)

type PreferenceHandler struct {
	pb.UnimplementedPreferenceServiceServer
	service *service.PreferenceService
	repo    *repository.PreferenceRepository
}

func NewPreferenceHandler(s *service.PreferenceService, r *repository.PreferenceRepository) *PreferenceHandler {
	return &PreferenceHandler{
		service: s,
		repo:    r,
	}
}

// 🧠 логика
func (h *PreferenceHandler) GetPreferences(ctx context.Context, req *pb.PreferenceRequest) (*pb.PreferenceResponse, error) {

	pref := model.Preference{
		UserID:    req.UserId,
		Mood:      req.Mood,
		TimeOfDay: req.TimeOfDay,
		Budget:    req.Budget,
	}

	categories := h.service.GetCategories(pref)

	return &pb.PreferenceResponse{
		Categories: categories,
	}, nil
}

// 💾 сохранить
func (h *PreferenceHandler) SavePreferences(ctx context.Context, req *pb.PreferenceRequest) (*pb.Empty, error) {

	pref := model.Preference{
		UserID:    req.UserId,
		Mood:      req.Mood,
		TimeOfDay: req.TimeOfDay,
		Budget:    req.Budget,
	}

	err := h.repo.Save(pref)
	if err != nil {
		return nil, err
	}

	return &pb.Empty{}, nil
}

// 📥 получить
func (h *PreferenceHandler) GetUserPreferences(ctx context.Context, req *pb.UserRequest) (*pb.PreferenceRequest, error) {

	pref, err := h.repo.GetByUserID(req.UserId)
	if err != nil {
		return nil, err
	}

	return &pb.PreferenceRequest{
		UserId:    pref.UserID,
		Mood:      pref.Mood,
		TimeOfDay: pref.TimeOfDay,
		Budget:    pref.Budget,
	}, nil
}
