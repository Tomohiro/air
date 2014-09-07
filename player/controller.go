package player

import (
	"errors"

	"github.com/gongo/go-airplay"
)

// A Controller can play media files
type Controller struct {
	Playlist *Playlist
}

// NewController returns a new controller
func NewController() *Controller {
	return new(Controller)
}

// SetPlaylist sets playlist
func (c *Controller) SetPlaylist(p *Playlist) error {
	if len(p.Entries) == 0 {
		return errors.New("media files not found")
	}
	c.Playlist = p
	return nil
}

// Play plays all entries in the playlist
func (c *Controller) Play() error {
	client, err := airplay.NewClient()
	if err != nil {
		return err
	}

	for _, media := range c.Playlist.Entries {
		ch := client.Play(media.URL())
		<-ch
	}
	return nil
}
