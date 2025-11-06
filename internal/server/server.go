package server

import (
	"context"

	pb "github.com/fredxfred/dog-api-grpc/proto/dogapi"
	"github.com/fredxfred/dog-api-grpc/internal/dogclient"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Server struct {
	pb.UnimplementedDogServiceServer
	client *dogclient.Client
}

func NewServer() *Server {
	return &Server{
		client: dogclient.NewClient(),
	}
}

func (s *Server) ListAllBreeds(ctx context.Context, req *pb.ListAllBreedsRequest) (*pb.ListAllBreedsResponse, error) {
	breeds, err := s.client.ListAllBreeds()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list breeds: %v", err)
	}

	resp := &pb.ListAllBreedsResponse{
		Breeds: make(map[string]*pb.SubBreeds),
	}

	for breed, subBreeds := range breeds {
		resp.Breeds[breed] = &pb.SubBreeds{
			SubBreeds: subBreeds,
		}
	}

	return resp, nil
}

func (s *Server) ListBreeds(ctx context.Context, req *pb.ListBreedsRequest) (*pb.ListBreedsResponse, error) {
	breeds, err := s.client.ListBreeds()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list breeds: %v", err)
	}

	return &pb.ListBreedsResponse{Breeds: breeds}, nil
}

func (s *Server) GetRandomImage(ctx context.Context, req *pb.GetRandomImageRequest) (*pb.GetRandomImageResponse, error) {
	imageURL, err := s.client.GetRandomImage()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get random image: %v", err)
	}

	return &pb.GetRandomImageResponse{ImageUrl: imageURL}, nil
}

func (s *Server) GetRandomImages(ctx context.Context, req *pb.GetRandomImagesRequest) (*pb.GetRandomImagesResponse, error) {
	if req.Count <= 0 || req.Count > 50 {
		return nil, status.Error(codes.InvalidArgument, "count must be between 1 and 50")
	}

	images, err := s.client.GetRandomImages(int(req.Count))
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get random images: %v", err)
	}

	return &pb.GetRandomImagesResponse{ImageUrls: images}, nil
}

func (s *Server) GetBreedImages(ctx context.Context, req *pb.GetBreedImagesRequest) (*pb.GetBreedImagesResponse, error) {
	if req.Breed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed is required")
	}

	images, err := s.client.GetBreedImages(req.Breed)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get breed images: %v", err)
	}

	return &pb.GetBreedImagesResponse{ImageUrls: images}, nil
}

func (s *Server) GetRandomBreedImage(ctx context.Context, req *pb.GetRandomBreedImageRequest) (*pb.GetRandomBreedImageResponse, error) {
	if req.Breed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed is required")
	}

	imageURL, err := s.client.GetRandomBreedImage(req.Breed)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get random breed image: %v", err)
	}

	return &pb.GetRandomBreedImageResponse{ImageUrl: imageURL}, nil
}

func (s *Server) GetRandomBreedImages(ctx context.Context, req *pb.GetRandomBreedImagesRequest) (*pb.GetRandomBreedImagesResponse, error) {
	if req.Breed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed is required")
	}
	if req.Count <= 0 || req.Count > 50 {
		return nil, status.Error(codes.InvalidArgument, "count must be between 1 and 50")
	}

	images, err := s.client.GetRandomBreedImages(req.Breed, int(req.Count))
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get random breed images: %v", err)
	}

	return &pb.GetRandomBreedImagesResponse{ImageUrls: images}, nil
}

func (s *Server) GetSubBreedImages(ctx context.Context, req *pb.GetSubBreedImagesRequest) (*pb.GetSubBreedImagesResponse, error) {
	if req.Breed == "" || req.SubBreed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed and sub-breed are required")
	}

	images, err := s.client.GetSubBreedImages(req.Breed, req.SubBreed)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get sub-breed images: %v", err)
	}

	return &pb.GetSubBreedImagesResponse{ImageUrls: images}, nil
}

func (s *Server) GetRandomSubBreedImage(ctx context.Context, req *pb.GetRandomSubBreedImageRequest) (*pb.GetRandomSubBreedImageResponse, error) {
	if req.Breed == "" || req.SubBreed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed and sub-breed are required")
	}

	imageURL, err := s.client.GetRandomSubBreedImage(req.Breed, req.SubBreed)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get random sub-breed image: %v", err)
	}

	return &pb.GetRandomSubBreedImageResponse{ImageUrl: imageURL}, nil
}

func (s *Server) ListSubBreeds(ctx context.Context, req *pb.ListSubBreedsRequest) (*pb.ListSubBreedsResponse, error) {
	if req.Breed == "" {
		return nil, status.Error(codes.InvalidArgument, "breed is required")
	}

	subBreeds, err := s.client.ListSubBreeds(req.Breed)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list sub-breeds: %v", err)
	}

	return &pb.ListSubBreedsResponse{SubBreeds: subBreeds}, nil
}
