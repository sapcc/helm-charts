package main

import (
	_ "embed"
	"fmt"
	"os"

	api "github.com/sapcc/helm-charts/common/mariadb-galera/operator/api/handler"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
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

	// start the webserver to serve the Galera status
	api.StartWebServer()
}
