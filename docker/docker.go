package docker

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"

	log "github.com/sirupsen/logrus"

	types "github.com/docker/docker/api/types"
	filters "github.com/docker/docker/api/types/filters"
	client "github.com/docker/docker/client"
)

// Client is client structure
type Client struct {
	client *client.Client
	debug  bool
}

// Config is client config
type Config struct {
	Debug bool
}

// NewClient creates a new client instance
func NewClient(config *Config) *Client {
	if config == nil {
		config = &Config{}
	}
	return newEnvClient(config)
}

// newEnvClient returns a new client instance based on environment variables
func newEnvClient(config *Config) *Client {
	ctx := context.Background()
	cl, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Fatalf("[docker] %s", err)
	}
	cl.NegotiateAPIVersion(ctx)

	return &Client{
		client: cl,
		debug:  config.Debug,
	}
}

// ImageSummary is structure for image summary
type ImageSummary struct {
	ID   string
	Tags []string
	Size int64
}

// ListImages return list of docker images
func (c *Client) ListImages() ([]*ImageSummary, error) {
	images, err := c.client.ImageList(context.Background(), types.ImageListOptions{
		All: true,
	})
	if err != nil {
		return nil, err
	}

	var summaries []*ImageSummary
	for _, image := range images {
		summaries = append(summaries, &ImageSummary{
			ID:   image.ID,
			Tags: image.RepoTags,
			Size: image.Size,
		})
	}

	return summaries, nil
}

// HasImage returns true if image ID is available locally
func (c *Client) HasImage(imageID string) (bool, error) {
	args := filters.NewArgs()
	args.Add("reference", StripImageTagHost(imageID))
	images, err := c.client.ImageList(context.Background(), types.ImageListOptions{
		All:     true,
		Filters: args,
	})
	if err != nil {
		return false, err
	}

	if len(images) > 0 {
		return true, nil
	}

	return false, nil
}

// PullImage pulls a docker image
func (c *Client) PullImage(imageID string) error {
	reader, err := c.client.ImagePull(context.Background(), imageID, types.ImagePullOptions{})
	if err != nil {
		return fmt.Errorf("[docker] error pulling image: %v", err)
	}
	defer reader.Close()

	io.Copy(ioutil.Discard, reader)

	return nil
}

// PushImage pushes a docker image
func (c *Client) PushImage(imageID string) error {
	reader, err := c.client.ImagePush(context.Background(), imageID, types.ImagePushOptions{
		// NOTE: if no auth, then any value is required
		RegistryAuth: "123",
	})
	if err != nil {
		return err
	}

	if c.debug {
		io.Copy(os.Stdout, reader)
	}

	return nil
}

// TagImage tags an image
func (c *Client) TagImage(imageID, tag string) error {
	return c.client.ImageTag(context.Background(), imageID, tag)
}

// RemoveImage remove an image from the local registry
func (c *Client) RemoveImage(imageID string) error {
	_, err := c.client.ImageRemove(context.Background(), imageID, types.ImageRemoveOptions{
		Force:         true,
		PruneChildren: true,
	})

	return err
}

// RemoveAllImages removes all images from the local registry
func (c *Client) RemoveAllImages() error {
	images, err := c.ListImages()
	if err != nil {
		return err
	}

	var lastErr error
	for _, image := range images {
		err := c.RemoveImage(image.ID)
		if err != nil {
			lastErr = err
			continue
		}
	}

	images, err = c.ListImages()
	if err != nil {
		return err
	}

	if len(images) != 0 {
		return lastErr
	}

	return nil
}

// ReadImage reads the contents of an image into an IO reader
func (c *Client) ReadImage(imageID string) (io.Reader, error) {
	return c.client.ImageSave(context.Background(), []string{imageID})
}

// LoadImage loads an image from an IO reader
func (c *Client) LoadImage(input io.Reader) error {
	output, err := c.client.ImageLoad(context.Background(), input, false)
	if err != nil {
		return err
	}

	body, err := ioutil.ReadAll(output.Body)
	c.Debugf("%s", string(body))

	return err
}

// LoadImage loads an image from an IO reader
func (c *Client) LoadImage2(input io.Reader) (string, error) {
	output, err := c.client.ImageLoad(context.Background(), input, false)
	if err != nil {
		return "", err
	}
	defer output.Body.Close()

	body, err := ioutil.ReadAll(output.Body)
	if err != nil {
		return "", err
	}
	c.Debugf("Response Body: %s", body)

	var result struct {
		Stream string `json:"stream"`
	}

	// Iterate over each line as the output may contain multiple JSON objects.
	for _, line := range strings.Split(string(body), "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}

		// Attempt to unmarshal each line into the result struct.
		if err := json.Unmarshal([]byte(line), &result); err == nil {
			if strings.Contains(result.Stream, "Loaded image ID: sha256:") {
				sha := strings.TrimPrefix(result.Stream, "Loaded image ID: sha256:")
				sha = strings.TrimSpace(sha) // Clean up any extra whitespace or newline characters.
				return sha, nil
			}
		}
	}

	return "", nil // Return an empty string if no SHA is found
}

// LoadImageByFilePath loads an image from a tarball
func (c *Client) LoadImageByFilePath(filepath string) error {
	input, err := os.Open(filepath)
	if err != nil {
		log.Errorf("[docker] load image by filepath error; %v", err)
		return err
	}
	return c.LoadImage(input)
}

// LoadImageByFilePath loads an image from a tarball
func (c *Client) LoadImageByFilePathV2(filepath string, tags []string) error {
	input, err := os.Open(filepath)
	if err != nil {
		log.Errorf("[docker] open image by filepath error; %v", err)
		return err
	}
	imageID, err := c.LoadImage2(input)
	if err != nil {
		log.Errorf("[docker] load image by filepath error; %v", err)
		return err
	}

	for _, tag := range tags {
		c.TagImage(imageID, tag)
	}

	log.Println("[docker] image id :", imageID)
	return err
}

// SaveImageTar saves an image into a tarball
func (c *Client) SaveImageTar(imageID string, dest string) error {
	reader, err := c.ReadImage(imageID)
	if err != nil {
		return err
	}

	fo, err := os.Create(dest)
	if err != nil {
		return err
	}

	defer fo.Close()

	io.Copy(fo, reader)
	return nil
}

// Debugf prints debug log
func (c *Client) Debugf(str string, args ...interface{}) {
	if c.debug {
		log.Printf(str, args...)
	}
}
