package main

import (
	_ "embed"
	"fmt"
	"os"
	"time"

	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/api"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/database"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/state"
	"go.uber.org/zap"
	"gopkg.in/yaml.v3"
)

// embed metadata file
//
//go:embed metadata.yaml
var metadataFile []byte

func main() {
	// parse the metadata information
	err := yaml.Unmarshal(metadataFile, &config.MetadataList)
	if err != nil {
		config.Log().Error("metadata parsing failed", zap.Error(err))
	}

	// If requested display the version and exit
	if *config.CmdLineOptions.Version {
		fmt.Println(config.MetadataList.Version)
		os.Exit(0)
	}

	// If requested display the build information and exit
	if *config.CmdLineOptions.BuildInfo {
		fmt.Println(config.BuildInfo())
		os.Exit(0)
	}

	// query the Galera status and store it in the local state file every 5 seconds
	ticker := time.NewTicker(5 * time.Second)
	done := make(chan struct{})
	go func() {
		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				state.StoreGaleraStatus(database.QueryGaleraStatus())
			}
		}
	}()

	// start the webserver to serve the Galera status
	api.StartWebServer()
}
