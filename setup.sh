#!/bin/bash

# Create directory structure
mkdir -p cmd/server cmd/client internal/server internal/dogclient proto/dogapi

# Create go.mod
cat > go.mod << 'EOF'
module github.com/fredxfred/dog-api-grpc

go 1.21

require (
	google.golang.org/grpc v1.60.1
	google.golang.org/protobuf v1.32.0
)

require (
	github.com/golang/protobuf v1.5.3 // indirect
	golang.org/x/net v0.20.0 // indirect
	golang.org/x/sys v0.16.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20240108191215-35c7eff3a6b1 // indirect
)
EOF

# Create proto file
cat > proto/dogapi/dogapi.proto << 'EOF'
syntax = "proto3";

package dogapi;

option go_package = "github.com/fredxfred/dog-api-grpc/proto/dogapi";

service DogService {
  rpc ListAllBreeds(ListAllBreedsRequest) returns (ListAllBreedsResponse);
  rpc ListBreeds(ListBreedsRequest) returns (ListBreedsResponse);
  rpc GetRandomImage(GetRandomImageRequest) returns (GetRandomImageResponse);
  rpc GetRandomImages(GetRandomImagesRequest) returns (GetRandomImagesResponse);
  rpc GetBreedImages(GetBreedImagesRequest) returns (GetBreedImagesResponse);
  rpc GetRandomBreedImage(GetRandomBreedImageRequest) returns (GetRandomBreedImageResponse);
  rpc GetRandomBreedImages(GetRandomBreedImagesRequest) returns (GetRandomBreedImagesResponse);
  rpc GetSubBreedImages(GetSubBreedImagesRequest) returns (GetSubBreedImagesResponse);
  rpc GetRandomSubBreedImage(GetRandomSubBreedImageRequest) returns (GetRandomSubBreedImageResponse);
  rpc ListSubBreeds(ListSubBreedsRequest) returns (ListSubBreedsResponse);
}

message ListAllBreedsRequest {}

message ListAllBreedsResponse {
  map<string, SubBreeds> breeds = 1;
}

message SubBreeds {
  repeated string sub_breeds = 1;
}

message ListBreedsRequest {}

message ListBreedsResponse {
  repeated string breeds = 1;
}

message GetRandomImageRequest {}

message GetRandomImageResponse {
  string image_url = 1;
}

message GetRandomImagesRequest {
  int32 count = 1;
}

message GetRandomImagesResponse {
  repeated string image_urls = 1;
}

message GetBreedImagesRequest {
  string breed = 1;
}

message GetBreedImagesResponse {
  repeated string image_urls = 1;
}

message GetRandomBreedImageRequest {
  string breed = 1;
}

message GetRandomBreedImageResponse {
  string image_url = 1;
}

message GetRandomBreedImagesRequest {
  string breed = 1;
  int32 count = 2;
}

message GetRandomBreedImagesResponse {
  repeated string image_urls = 1;
}

message GetSubBreedImagesRequest {
  string breed = 1;
  string sub_breed = 2;
}

message GetSubBreedImagesResponse {
  repeated string image_urls = 1;
}

message GetRandomSubBreedImageRequest {
  string breed = 1;
  string sub_breed = 2;
}

message GetRandomSubBreedImageResponse {
  string image_url = 1;
}

message ListSubBreedsRequest {
  string breed = 1;
}

message ListSubBreedsResponse {
  repeated string sub_breeds = 1;
}
EOF

# Create dogclient
cat > internal/dogclient/client.go << 'EOF'
package dogclient

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const baseURL = "https://dog.ceo/api"

type Client struct {
	httpClient *http.Client
}

type APIResponse struct {
	Status  string      `json:"status"`
	Message interface{} `json:"message"`
}

func NewClient() *Client {
	return &Client{
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (c *Client) doRequest(url string) (*APIResponse, error) {
	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var apiResp APIResponse
	if err := json.Unmarshal(body, &apiResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if apiResp.Status != "success" {
		return nil, fmt.Errorf("api returned error status: %s", apiResp.Status)
	}

	return &apiResp, nil
}

func (c *Client) ListAllBreeds() (map[string][]string, error) {
	url := fmt.Sprintf("%s/breeds/list/all", baseURL)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	breeds := make(map[string][]string)
	messageMap, ok := resp.Message.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	for breed, subBreedsInterface := range messageMap {
		subBreedsList, ok := subBreedsInterface.([]interface{})
		if !ok {
			continue
		}
		var subBreeds []string
		for _, sb := range subBreedsList {
			if sbStr, ok := sb.(string); ok {
				subBreeds = append(subBreeds, sbStr)
			}
		}
		breeds[breed] = subBreeds
	}

	return breeds, nil
}

func (c *Client) ListBreeds() ([]string, error) {
	url := fmt.Sprintf("%s/breeds/list", baseURL)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	breedsList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var breeds []string
	for _, b := range breedsList {
		if breed, ok := b.(string); ok {
			breeds = append(breeds, breed)
		}
	}

	return breeds, nil
}

func (c *Client) GetRandomImage() (string, error) {
	url := fmt.Sprintf("%s/breeds/image/random", baseURL)
	resp, err := c.doRequest(url)
	if err != nil {
		return "", err
	}

	imageURL, ok := resp.Message.(string)
	if !ok {
		return "", fmt.Errorf("unexpected message format")
	}

	return imageURL, nil
}

func (c *Client) GetRandomImages(count int) ([]string, error) {
	url := fmt.Sprintf("%s/breeds/image/random/%d", baseURL, count)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	imagesList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var images []string
	for _, img := range imagesList {
		if imageURL, ok := img.(string); ok {
			images = append(images, imageURL)
		}
	}

	return images, nil
}

func (c *Client) GetBreedImages(breed string) ([]string, error) {
	url := fmt.Sprintf("%s/breed/%s/images", baseURL, breed)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	imagesList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var images []string
	for _, img := range imagesList {
		if imageURL, ok := img.(string); ok {
			images = append(images, imageURL)
		}
	}

	return images, nil
}

func (c *Client) GetRandomBreedImage(breed string) (string, error) {
	url := fmt.Sprintf("%s/breed/%s/images/random", baseURL, breed)
	resp, err := c.doRequest(url)
	if err != nil {
		return "", err
	}

	imageURL, ok := resp.Message.(string)
	if !ok {
		return "", fmt.Errorf("unexpected message format")
	}

	return imageURL, nil
}

func (c *Client) GetRandomBreedImages(breed string, count int) ([]string, error) {
	url := fmt.Sprintf("%s/breed/%s/images/random/%d", baseURL, breed, count)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	imagesList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var images []string
	for _, img := range imagesList {
		if imageURL, ok := img.(string); ok {
			images = append(images, imageURL)
		}
	}

	return images, nil
}

func (c *Client) GetSubBreedImages(breed, subBreed string) ([]string, error) {
	url := fmt.Sprintf("%s/breed/%s/%s/images", baseURL, breed, subBreed)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	imagesList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var images []string
	for _, img := range imagesList {
		if imageURL, ok := img.(string); ok {
			images = append(images, imageURL)
		}
	}

	return images, nil
}

func (c *Client) GetRandomSubBreedImage(breed, subBreed string) (string, error) {
	url := fmt.Sprintf("%s/breed/%s/%s/images/random", baseURL, breed, subBreed)
	resp, err := c.doRequest(url)
	if err != nil {
		return "", err
	}

	imageURL, ok := resp.Message.(string)
	if !ok {
		return "", fmt.Errorf("unexpected message format")
	}

	return imageURL, nil
}

func (c *Client) ListSubBreeds(breed string) ([]string, error) {
	url := fmt.Sprintf("%s/breed/%s/list", baseURL, breed)
	resp, err := c.doRequest(url)
	if err != nil {
		return nil, err
	}

	subBreedsList, ok := resp.Message.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected message format")
	}

	var subBreeds []string
	for _, sb := range subBreedsList {
		if subBreed, ok := sb.(string); ok {
			subBreeds = append(subBreeds, subBreed)
		}
	}

	return subBreeds, nil
}
EOF

# Create server
cat > internal/server/server.go << 'EOF'
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
EOF

# Create server main
cat > cmd/server/main.go << 'EOF'
package main

import (
	"flag"
	"fmt"
	"log"
	"net"

	pb "github.com/fredxfred/dog-api-grpc/proto/dogapi"
	"github.com/fredxfred/dog-api-grpc/internal/server"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

var (
	port = flag.Int("port", 50051, "The server port")
)

func main() {
	flag.Parse()

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterDogServiceServer(s, server.NewServer())
	
	reflection.Register(s)

	log.Printf("Server listening at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
EOF

# Create client main
cat > cmd/client/main.go << 'EOF'
package main

import (
	"context"
	"flag"
	"log"
	"time"

	pb "github.com/fredxfred/dog-api-grpc/proto/dogapi"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	addr = flag.String("addr", "localhost:50051", "the address to connect to")
)

func main() {
	flag.Parse()

	conn, err := grpc.NewClient(*addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()

	client := pb.NewDogServiceClient(conn)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Println("Getting a random dog image...")
	randomImg, err := client.GetRandomImage(ctx, &pb.GetRandomImageRequest{})
	if err != nil {
		log.Fatalf("could not get random image: %v", err)
	}
	log.Printf("Random image URL: %s\n\n", randomImg.ImageUrl)

	log.Println("Listing all breeds...")
	allBreeds, err := client.ListAllBreeds(ctx, &pb.ListAllBreedsRequest{})
	if err != nil {
		log.Fatalf("could not list breeds: %v", err)
	}
	log.Printf("Found %d breeds\n", len(allBreeds.Breeds))
	for breed, subBreeds := range allBreeds.Breeds {
		if len(subBreeds.SubBreeds) > 0 {
			log.Printf("  %s: %v\n", breed, subBreeds.SubBreeds)
		} else {
			log.Printf("  %s\n", breed)
		}
	}
	log.Println()

	log.Println("Getting 3 random husky images...")
	breedImages, err := client.GetRandomBreedImages(ctx, &pb.GetRandomBreedImagesRequest{
		Breed: "husky",
		Count: 3,
	})
	if err != nil {
		log.Fatalf("could not get breed images: %v", err)
	}
	for i, url := range breedImages.ImageUrls {
		log.Printf("  Image %d: %s\n", i+1, url)
	}
	log.Println()

	log.Println("Getting a random cocker spaniel image...")
	subBreedImg, err := client.GetRandomSubBreedImage(ctx, &pb.GetRandomSubBreedImageRequest{
		Breed:    "spaniel",
		SubBreed: "cocker",
	})
	if err != nil {
		log.Fatalf("could not get sub-breed image: %v", err)
	}
	log.Printf("Cocker Spaniel image: %s\n", subBreedImg.ImageUrl)
}
EOF

# Create Makefile
cat > Makefile << 'EOF'
.PHONY: proto clean build run-server run-client

proto:
	protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		proto/dogapi/dogapi.proto

clean:
	rm -f proto/dogapi/*.pb.go

build:
	go build -o bin/server cmd/server/main.go
	go build -o bin/client cmd/client/main.go

run-server:
	go run cmd/server/main.go

run-client:
	go run cmd/client/main.go

deps:
	go mod download
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
EOF

# Create README
cat > README.md << 'EOF'
# Dog CEO API - gRPC Wrapper

A gRPC wrapper around the dog.ceo REST API.

## Setup

1. Install dependencies:
```bash
make deps
```

2. Generate protobuf code:
```bash
make proto
```

3. Start the server:
```bash
make run-server
```

4. Run the client (in another terminal):
```bash
make run-client
```
EOF

echo "✅ All files created successfully!"
echo ""
echo "Next steps:"
echo "1. cd into your project directory"
echo "2. Run: go mod tidy"
echo "3. Run: make deps"
echo "4. Run: make proto"
echo "5. Run: make run-server"
