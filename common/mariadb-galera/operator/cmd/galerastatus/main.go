package main

import (
	_ "embed"
	"fmt"
	"net/http"
	"os"

	api "github.com/sapcc/helm-charts/common/mariadb-galera/operator/api/handler"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"gopkg.in/yaml.v3"
)

// embed metadata file
//
//go:embed metadata.yaml
var metadataFile []byte

func main() {
	// parse the metadata information
	metadataParseErr := yaml.Unmarshal(metadataFile, &config.MetadataList)
	config.ECSLogOutput(metadataParseErr, "error")

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

	http.HandleFunc("/status", api.GetGaleraStatus)
	http.ListenAndServe(":8080", nil)
}
