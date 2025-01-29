package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"slices"
	"strings"

	"github.com/bwmarrin/discordgo"
)

// Bot parameters
var (
	GuildID          string
	BotToken         string
	StreamApiBaseUrl string
	AdminIds         []string
	RemoveCommands   bool = false
)

func init() {
	var found bool
	GuildID, found = os.LookupEnv("DISCORD_GUILD_ID")
	if !found {
		log.Fatal("DISCORD_GUILD_ID envvar not found")
	}
	BotToken, found = os.LookupEnv("DISCORD_TOKEN")
	if !found {
		log.Fatal("DISCORD_TOKEN envvar not found")
	}
	StreamApiBaseUrl, found = os.LookupEnv("STREAM_API_BASE_URL")
	if !found {
		log.Fatal("STREAM_API_BASE_URL envvar not found")
	}
	admin, found := os.LookupEnv("ADMINS")
	if !found {
		log.Fatal("ADMINS envvar not found")
	}
	AdminIds = strings.Split(admin, ",")
}

var s *discordgo.Session

func init() {
	var err error
	s, err = discordgo.New("Bot " + BotToken)
	if err != nil {
		log.Fatalf("Invalid bot parameters: %v", err)
	}
}

type StreamType int

const (
	StreamTypeRTMP StreamType = iota + 1
	StreamTypeRTMPS
)

var (
	commands = []*discordgo.ApplicationCommand{
		{
			Name:        "stream",
			Description: "controls for the konstream streaming server",
			Options: []*discordgo.ApplicationCommandOption{
				{
					Type:        1,
					Name:        "list",
					Description: "List all running streams",
				},
				{
					Type:        1,
					Name:        "kick",
					Description: "Kick a running streams",
					Options: []*discordgo.ApplicationCommandOption{
						{
							Type:         3,
							Name:         "name",
							Description:  "Name of the stream (without 'live/')",
							Required:     true,
							Autocomplete: true,
						},
					},
				},
			},
		},
	}

	commandHandlers = map[string]func(s *discordgo.Session, i *discordgo.InteractionCreate){
		"stream": func(s *discordgo.Session, i *discordgo.InteractionCreate) {
			switch i.Type {
			case discordgo.InteractionApplicationCommand:
				data := i.ApplicationCommandData()
				options := data.Options
				switch options[0].Name {
				case "list":
					streams, err := getRtmpStreams()

					if err == nil {
						res := make([]string, len(streams))
						for i, stream := range streams {
							res[i] = fmt.Sprintf("%s is streamed by %s", stream.Name, stream.User)
						}

						err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
							Type: discordgo.InteractionResponseChannelMessageWithSource,
							Data: &discordgo.InteractionResponseData{
								Embeds: []*discordgo.MessageEmbed{
									{
										Title:       "Active Streams",
										Description: strings.Join(res, "\n"),
									},
								},
							},
						})
						if err != nil {
							panic(err)
						}
					} else {
						err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
							Type: discordgo.InteractionResponseChannelMessageWithSource,
							Data: &discordgo.InteractionResponseData{
								Content: "failed to fetch streams",
							},
						})
						if err != nil {
							panic(err)
						}
					}
					break
				case "kick":
					streams, err := getRtmpStreams()

					response := ""
					if err == nil {
						toLook := options[0].Options[0].Value
						index := slices.IndexFunc(streams, func(e *rtmpStreamInfo) bool {
							return e.Name == toLook
						})
						if index > -1 {
							stream := streams[index]
							typeString := "rtmpconns"
							if stream.Type == StreamTypeRTMPS {
								typeString = "rtmpsconns"
							}
							log.Printf("kicking %s (%s)", stream.Name, stream.Id)

							_, err := http.PostForm(fmt.Sprintf("%s/%s/kick/%s", StreamApiBaseUrl, typeString, stream.Id), url.Values{})
							if err == nil {
								log.Printf("%s (%s) was kicked", stream.Name, stream.Id)
								response = fmt.Sprintf("%s was kicked", toLook)
							} else {
								response = fmt.Sprintf("%s could not be kicked", toLook)
							}
						} else {
							response = fmt.Sprintf("%s was not found", toLook)
						}
					} else {
						response = "failed to fetch streams"
					}
					err = s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
						Type: discordgo.InteractionResponseChannelMessageWithSource,
						Data: &discordgo.InteractionResponseData{Content: response},
					})
					if err != nil {
						panic(err)
					}
					break
				default:
					err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
						Type: discordgo.InteractionResponseChannelMessageWithSource,
						Data: &discordgo.InteractionResponseData{
							Content: fmt.Sprintf("unknown subcommand: %v", options[0].Name),
						},
					})
					if err != nil {
						panic(err)
					}
				}
			case discordgo.InteractionApplicationCommandAutocomplete:
				data := i.ApplicationCommandData()
				for _, opt := range data.Options {
					switch opt.Name {
					case "kick":
						for _, opt := range opt.Options {
							if opt.Focused {
								switch opt.Name {
								case "name":
									streams, err := getRtmpStreams()
									// If err just don't send anything back
									if err == nil {
										res := make([]*discordgo.ApplicationCommandOptionChoice, len(streams))
										for i, stream := range streams {
											res[i] = &discordgo.ApplicationCommandOptionChoice{
												Name:  stream.Name,
												Value: stream.Name,
											}
										}

										err = s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
											Type: discordgo.InteractionApplicationCommandAutocompleteResult,
											Data: &discordgo.InteractionResponseData{Choices: res},
										})
										if err != nil {
											panic(err)
										}
									}
									break
								default:
									log.Fatalf("unknown opt name: %s", opt.Name)
								}
							}
						}
						break
					}
				}
			}
		},
	}
)

type rtmpStreamInfo struct {
	Type StreamType
	Id   string
	Name string
	User string
}

func getRtmpStreams() ([]*rtmpStreamInfo, error) {
	res, err := http.Get(fmt.Sprintf("%s/v3/rtmpconns/list", StreamApiBaseUrl))
	if err == nil {
		if res.Body != nil {
			defer res.Body.Close()
		}

		body, err := io.ReadAll(res.Body)
		if err != nil {
			return nil, err
		}
		type ApiResponse struct {
			Items []struct {
				Id    string `json:"id"`
				Path  string `json:"path"`
				Query string `json:"query"`
			} `json:"items"`
		}
		rtmp_streams := ApiResponse{}
		err = json.Unmarshal(body, &rtmp_streams)
		if err != nil {
			return nil, err
		}

		res, err = http.Get(fmt.Sprintf("%s/v3/rtmpsconns/list", StreamApiBaseUrl))
		rtmps_streams, rtmps_avail := ApiResponse{}, false
		if err == nil {
			if res.Body != nil {
				defer res.Body.Close()
			}
			body, err = io.ReadAll(res.Body)
			if err != nil {
				goto BREAK
			}

			err = json.Unmarshal(body, &rtmps_streams)
			if err != nil {
				goto BREAK
			}
			rtmps_avail = true
		BREAK:
		}

		length := len(rtmp_streams.Items)
		if rtmps_avail {
			length += len(rtmps_streams.Items)
		}

		res := make([]*rtmpStreamInfo, length)

		for i, item := range rtmp_streams.Items {
			name, _ := strings.CutPrefix(item.Path, "live/")
			val, err := url.ParseQuery(item.Query)
			user := "unknown"
			if err == nil && val.Has("username") {
				user = val.Get("username")
			}
			res[i] = &rtmpStreamInfo{
				Type: StreamTypeRTMP,
				Id:   item.Id,
				Name: name,
				User: user,
			}
		}

		if rtmps_avail {
			length := len(rtmp_streams.Items)
			for i, item := range rtmps_streams.Items {
				name, _ := strings.CutPrefix(item.Path, "live/")
				val, err := url.ParseQuery(item.Query)
				user := "unknown"
				if err == nil && val.Has("username") {
					user = val.Get("username")
				}
				res[length+i] = &rtmpStreamInfo{
					Type: StreamTypeRTMPS,
					Id:   item.Id,
					Name: name,
					User: user,
				}
			}
		}
		return res, nil
	}
	return nil, errors.New("could not fetch rtmp streams")
}

func main() {
	s.AddHandler(func(s *discordgo.Session, r *discordgo.Ready) { log.Println("Bot is up!") })
	s.AddHandler(func(s *discordgo.Session, i *discordgo.InteractionCreate) {
		if slices.Index(AdminIds, i.Interaction.Member.User.ID) == -1 {
			err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
				Type: discordgo.InteractionResponseChannelMessageWithSource,
				Data: &discordgo.InteractionResponseData{Content: "Nope"},
			})
			if err != nil {
				panic(err)
			}
			return
		}
		if h, ok := commandHandlers[i.ApplicationCommandData().Name]; ok {
			h(s, i)
		}
	})

	err := s.Open()
	if err != nil {
		log.Fatalf("Cannot open the session: %v", err)
	}

	defer s.Close()

	createdCommands, err := s.ApplicationCommandBulkOverwrite(s.State.User.ID, GuildID, commands)

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	<-stop
	log.Println("Gracefully shutting down")

	if RemoveCommands {
		for _, cmd := range createdCommands {
			err := s.ApplicationCommandDelete(s.State.User.ID, GuildID, cmd.ID)
			if err != nil {
				log.Fatalf("Cannot delete %q command: %v", cmd.Name, err)
			}
		}
	}

}
