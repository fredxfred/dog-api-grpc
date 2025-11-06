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
