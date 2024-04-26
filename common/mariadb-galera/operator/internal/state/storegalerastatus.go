package state

import (
	"encoding/json"
	"os"

	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/database"
	"go.uber.org/zap"
)

func StoreGaleraStatus(galeraStatus *database.GaleraStatus, statusErr error) {

	if statusErr != nil {
		config.Log().Error("database query has been failed", zap.Error(statusErr))
		return
	}

	var (
		filename string = *config.CmdLineOptions.StatusFile
	)

	file, err := os.Create(filename)
	if err != nil {
		config.Log().Error("could not create "+filename, zap.Error(err))
		return
	}
	config.Log().Info(filename + " created")
	defer file.Close()

	bytes, err := json.Marshal(galeraStatus)
	if err != nil {
		config.Log().Error("json parsing for the Galera status failed", zap.Error(err))
		return
	}

	_, err = file.Write(bytes)
	if err != nil {
		config.Log().Error("could not write into "+filename, zap.Error(err))
		return
	}
	config.Log().Info("Galera status written into " + filename)
}
