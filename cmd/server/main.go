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
