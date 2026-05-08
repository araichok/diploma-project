package service

import (
	"errors"
	"time"

	"user-service/internal/auth"
	"user-service/internal/cache"
	"user-service/internal/model"
	"user-service/internal/repository"
)

type UserService struct {
	userRepo  *repository.UserRepository
	userCache *cache.UserCache
	jwtSecret string
}

func NewUserService(
	userRepo *repository.UserRepository,
	userCache *cache.UserCache,
	jwtSecret string,
) *UserService {
	return &UserService{
		userRepo:  userRepo,
		userCache: userCache,
		jwtSecret: jwtSecret,
	}
}

func (s *UserService) Register(req model.RegisterRequest) (*model.User, error) {
	if req.FirstName == "" || req.LastName == "" || req.Email == "" || req.Password == "" {
		return nil, errors.New("all fields are required")
	}

	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Email:        req.Email,
		PasswordHash: hashedPassword,
	}

	err = s.userRepo.CreateUser(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *UserService) Login(req model.LoginRequest) (*model.LoginResponse, error) {
	if req.Email == "" || req.Password == "" {
		return nil, errors.New("email and password are required")
	}

	user, err := s.userRepo.GetUserByEmail(req.Email)
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		return nil, errors.New("invalid email or password")
	}

	accessToken, err := auth.GenerateToken(
		user.ID,
		user.Email,
		user.Role,
		s.jwtSecret,
	)
	if err != nil {
		return nil, err
	}

	refreshToken, err := auth.GenerateRefreshToken(
		user.ID,
		user.Email,
		user.Role,
		s.jwtSecret,
	)
	if err != nil {
		return nil, err
	}

	err = s.userRepo.SaveRefreshToken(
		user.ID,
		refreshToken,
		time.Now().Add(7*24*time.Hour),
	)
	if err != nil {
		return nil, err
	}

	return &model.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (s *UserService) GetProfile(id string) (*model.User, error) {
	if id == "" {
		return nil, errors.New("user id is required")
	}

	cachedUser, err := s.userCache.GetUser(id)
	if err == nil {
		return cachedUser, nil
	}

	user, err := s.userRepo.GetUserByID(id)
	if err != nil {
		return nil, err
	}

	_ = s.userCache.SetUser(user)

	return user, nil
}

func (s *UserService) UpdateUser(id string, req model.UpdateUserRequest) (*model.User, error) {
	if id == "" {
		return nil, errors.New("user id is required")
	}

	if req.FirstName == "" || req.LastName == "" || req.Email == "" {
		return nil, errors.New("all fields are required")
	}

	user, err := s.userRepo.UpdateUser(id, req)
	if err != nil {
		return nil, err
	}

	_ = s.userCache.SetUser(user)

	return user, nil
}

func (s *UserService) DeleteUser(id string) error {
	if id == "" {
		return errors.New("user id is required")
	}

	err := s.userRepo.DeleteUser(id)
	if err != nil {
		return err
	}

	_ = s.userCache.DeleteUser(id)

	return nil
}
func (s *UserService) RefreshToken(refreshToken string) (*model.LoginResponse, error) {
	if refreshToken == "" {
		return nil, errors.New("refresh token is required")
	}

	userID, err := s.userRepo.GetRefreshToken(refreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	user, err := s.userRepo.GetUserByID(userID)
	if err != nil {
		return nil, err
	}

	accessToken, err := auth.GenerateToken(
		user.ID,
		user.Email,
		user.Role,
		s.jwtSecret,
	)
	if err != nil {
		return nil, err
	}

	return &model.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (s *UserService) Logout(refreshToken string) error {
	if refreshToken == "" {
		return errors.New("refresh token is required")
	}

	return s.userRepo.DeleteRefreshToken(refreshToken)
}
