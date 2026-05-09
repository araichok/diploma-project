package handler

import (
	"context"

	"user-service/internal/model"
	"user-service/internal/service"
	"user-service/proto/userpb"
)

type UserGrpcHandler struct {
	userpb.UnimplementedUserServiceServer
	userService *service.UserService
}

func NewUserGrpcHandler(userService *service.UserService) *UserGrpcHandler {
	return &UserGrpcHandler{
		userService: userService,
	}
}

func (h *UserGrpcHandler) Register(
	ctx context.Context,
	req *userpb.RegisterRequest,
) (*userpb.UserResponse, error) {

	user, err := h.userService.Register(model.RegisterRequest{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  req.Password,
	})

	if err != nil {
		return nil, err
	}

	return &userpb.UserResponse{
		Id:        user.ID,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Role:      user.Role,
	}, nil
}

func (h *UserGrpcHandler) Login(
	ctx context.Context,
	req *userpb.LoginRequest,
) (*userpb.LoginResponse, error) {

	loginResponse, err := h.userService.Login(model.LoginRequest{
		Email:    req.Email,
		Password: req.Password,
	})

	if err != nil {
		return nil, err
	}

	user := loginResponse.User

	return &userpb.LoginResponse{
		AccessToken:  loginResponse.AccessToken,
		RefreshToken: loginResponse.RefreshToken,
		User: &userpb.UserResponse{
			Id:        user.ID,
			FirstName: user.FirstName,
			LastName:  user.LastName,
			Email:     user.Email,
			Role:      user.Role,
		},
	}, nil
}

func (h *UserGrpcHandler) GetProfile(
	ctx context.Context,
	req *userpb.GetProfileRequest,
) (*userpb.UserResponse, error) {

	user, err := h.userService.GetProfile(req.Id)
	if err != nil {
		return nil, err
	}

	return &userpb.UserResponse{
		Id:        user.ID,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Role:      user.Role,
	}, nil
}

func (h *UserGrpcHandler) UpdateUser(
	ctx context.Context,
	req *userpb.UpdateUserRequest,
) (*userpb.UserResponse, error) {

	user, err := h.userService.UpdateUser(
		req.Id,
		model.UpdateUserRequest{
			FirstName: req.FirstName,
			LastName:  req.LastName,
			Email:     req.Email,
		},
	)

	if err != nil {
		return nil, err
	}

	return &userpb.UserResponse{
		Id:        user.ID,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Role:      user.Role,
	}, nil
}

func (h *UserGrpcHandler) DeleteUser(
	ctx context.Context,
	req *userpb.DeleteUserRequest,
) (*userpb.DeleteUserResponse, error) {

	err := h.userService.DeleteUser(req.Id)
	if err != nil {
		return nil, err
	}

	return &userpb.DeleteUserResponse{
		Message: "User deleted successfully",
	}, nil
}

func (h *UserGrpcHandler) RefreshToken(
	ctx context.Context,
	req *userpb.RefreshTokenRequest,
) (*userpb.LoginResponse, error) {

	loginResponse, err := h.userService.RefreshToken(req.RefreshToken)
	if err != nil {
		return nil, err
	}

	user := loginResponse.User

	return &userpb.LoginResponse{
		AccessToken:  loginResponse.AccessToken,
		RefreshToken: loginResponse.RefreshToken,
		User: &userpb.UserResponse{
			Id:        user.ID,
			FirstName: user.FirstName,
			LastName:  user.LastName,
			Email:     user.Email,
			Role:      user.Role,
		},
	}, nil
}

func (h *UserGrpcHandler) Logout(
	ctx context.Context,
	req *userpb.LogoutRequest,
) (*userpb.LogoutResponse, error) {

	err := h.userService.Logout(req.RefreshToken)
	if err != nil {
		return nil, err
	}

	return &userpb.LogoutResponse{
		Message: "Logged out successfully",
	}, nil
}

func (h *UserGrpcHandler) ChangePassword(
	ctx context.Context,
	req *userpb.ChangePasswordRequest,
) (*userpb.ChangePasswordResponse, error) {

	err := h.userService.ChangePassword(model.ChangePasswordRequest{
		UserID:      req.UserId,
		OldPassword: req.OldPassword,
		NewPassword: req.NewPassword,
	})

	if err != nil {
		return nil, err
	}

	return &userpb.ChangePasswordResponse{
		Message: "Password changed successfully",
	}, nil
}
