package api

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"go.uber.org/zap"
)

func GetGaleraStatus(w http.ResponseWriter, r *http.Request) {
	var (
		filename string = *config.CmdLineOptions.StatusFile
		jsonMap  map[string]interface{}
	)
	// galeraStatus, err := database.QueryGaleraStatus()
	// if err != nil {
	// 	config.Log().Error("database query has been failed", zap.Error(err))
	// 	http.Error(w, "database backend problem occured", http.StatusInternalServerError)
	// 	return
	// }

	// bytes, err := json.Marshal(galeraStatus)
	// if err != nil {
	// 	config.Log().Error("json parsing for the Galera status failed", zap.Error(err))
	// 	http.Error(w, "data parsing problem occured", http.StatusInternalServerError)
	// 	return
	// }

	file, err := os.ReadFile(filename)
	if err != nil {
		config.Log().Error("could not read "+filename, zap.Error(err))
		return
	}

	err = json.Unmarshal(file, &jsonMap)
	if err != nil {
		config.Log().Error("could not parse "+filename, zap.Error(err))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(file)
}

func StartWebServer() {
	config.Log().Info("starting webserver on http://localhost:8080/status")
	http.HandleFunc("/status", GetGaleraStatus)
	err := http.ListenAndServe("localhost:8080", nil)
	if err != nil {
		config.Log().Fatal("webserver startup failed", zap.Error(err))
	}
}
