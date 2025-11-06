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
