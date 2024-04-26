package database

import (
	"database/sql"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"go.uber.org/zap"
)

type galeraStatus struct {
	Cluster    cluster `json:"cluster"`
	Node       node    `json:"node"`
	LastUpdate string  `json:"last_update"`
}

type cluster struct {
	Size      int    `json:"size"`
	Status    string `json:"status"`
	Partition string `json:"partition"`
}

type node struct {
	State     string `json:"state"`
	Connected string `json:"connected"`
	Ready     string `json:"ready"`
	Seqno     int    `json:"seqno"`
}

func QueryGaleraStatus() (*galeraStatus, error) {
	var (
		preparedStatement *sql.Stmt
		status            galeraStatus
		columnName        string
		queryValue        string
		updateTime        time.Time = time.Now()
	)

	preparedStatement, err := DB().Prepare("SHOW GLOBAL STATUS WHERE variable_name=?")
	if err != nil {
		config.Log().Error("creating prepared statement for database query failed", zap.Error(err))
		return nil, err
	}
	defer preparedStatement.Close()

	queryValue = "wsrep_cluster_size"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Cluster.Size)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_cluster_status"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Cluster.Partition)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_local_state_comment"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Node.State)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_connected"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Node.Connected)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_ready"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Node.Ready)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_last_committed"
	err = preparedStatement.QueryRow(queryValue).Scan(&columnName, &status.Node.Seqno)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	if strings.ToLower(status.Cluster.Partition) == "primary" && status.Node.State == "Synced" && status.Node.Connected == "ON" && status.Node.Ready == "ON" {
		status.Cluster.Status = "healthy"
	} else {
		status.Cluster.Status = "unhealthy"
	}

	status.LastUpdate = updateTime.Format(time.RFC3339)

	return &status, nil
}
