package api

import (
	"encoding/json"
	"net/http"

	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/database"
)

func GetGaleraStatus(w http.ResponseWriter, r *http.Request) {
	galeraStatus, err := database.QueryGaleraStatus()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	bytes, err := json.Marshal(galeraStatus)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(bytes)
}
