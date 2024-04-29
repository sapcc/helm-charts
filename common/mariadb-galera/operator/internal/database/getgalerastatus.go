package database

import (
	"database/sql"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
	"go.uber.org/zap"
)

type GaleraStatus struct {
	Cluster    cluster `json:"cluster"`
	Node       node    `json:"node"`
	LastUpdate string  `json:"last_update"`
}

type cluster struct {
	Size      int    `json:"size"`
	Status    string `json:"status"`
	Partition string `json:"partition"`
	SegmentId int    `json:"segment_id"`
}

type node struct {
	WsrepName string `json:"wsrepname"`
	Hostname  string `json:"hostname"`
	State     string `json:"state"`
	Connected string `json:"connected"`
	Ready     string `json:"ready"`
	Seqno     int    `json:"seqno"`
}

func QueryGaleraStatus() (*GaleraStatus, error) {
	var (
		globalStatus *sql.Stmt
		globalVars   *sql.Stmt
		status       GaleraStatus
		columnName   string
		queryValue   string
		updateTime   time.Time = time.Now()
		err          error
	)

	globalStatus, err = DB().Prepare("SHOW GLOBAL STATUS WHERE variable_name=?")
	if err != nil {
		config.Log().Error("prepare statement for global status query failed", zap.Error(err))
		return nil, err
	}
	defer globalStatus.Close()

	globalVars, err = DB().Prepare("SHOW GLOBAL VARIABLES WHERE variable_name=?")
	if err != nil {
		config.Log().Error("prepare statement for global variables query failed", zap.Error(err))
		return nil, err
	}
	defer globalVars.Close()

	queryValue = "wsrep_cluster_size"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Cluster.Size)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_cluster_status"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Cluster.Partition)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_local_state_comment"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Node.State)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_connected"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Node.Connected)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_ready"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Node.Ready)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_last_committed"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Node.Seqno)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_gmcast_segment"
	err = globalStatus.QueryRow(queryValue).Scan(&columnName, &status.Cluster.SegmentId)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "wsrep_node_name"
	err = globalVars.QueryRow(queryValue).Scan(&columnName, &status.Node.WsrepName)
	if err != nil {
		config.Log().Error(queryValue+" query failed", zap.Error(err))
	} else {
		config.Log().Info(queryValue + " query successful")
	}

	queryValue = "hostname"
	err = globalVars.QueryRow(queryValue).Scan(&columnName, &status.Node.Hostname)
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
