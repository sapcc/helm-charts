package database

import (
	"database/sql"
	"strings"

	_ "github.com/go-sql-driver/mysql"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
)

type GaleraStatus struct {
	Cluster Cluster `json:"cluster"`
	Node    Node    `json:"node"`
}

type Cluster struct {
	Size      int    `json:"size"`
	Status    string `json:"status"`
	Partition string `json:"partition"`
}

type Node struct {
	State     string `json:"state"`
	Connected string `json:"connected"`
	Ready     string `json:"ready"`
	Seqno     int    `json:"seqno"`
}

func QueryGaleraStatus() (*GaleraStatus, error) {
	var preparedStatement *sql.Stmt
	var galeraStatus GaleraStatus
	var columnName string

	preparedStatement, err := DB().Prepare("SHOW GLOBAL STATUS WHERE variable_name=?")
	if err != nil {
		config.ECSLogOutput(err, "error")
	}
	defer preparedStatement.Close()

	err = preparedStatement.QueryRow("wsrep_cluster_size").Scan(&columnName, &galeraStatus.Cluster.Size)
	if err != nil {
		config.ECSLogOutput("wsrep_cluster_size query failed because of '"+err.Error()+"'", "error")
	}

	err = preparedStatement.QueryRow("wsrep_cluster_status").Scan(&columnName, &galeraStatus.Cluster.Partition)
	if err != nil {
		config.ECSLogOutput("wsrep_cluster_status query failed because of '"+err.Error()+"'", "error")
	}

	err = preparedStatement.QueryRow("wsrep_local_state_comment").Scan(&columnName, &galeraStatus.Node.State)
	if err != nil {
		config.ECSLogOutput("wsrep_local_state_comment query failed because of '"+err.Error()+"'", "error")
	}

	err = preparedStatement.QueryRow("wsrep_connected").Scan(&columnName, &galeraStatus.Node.Connected)
	if err != nil {
		config.ECSLogOutput("wsrep_connected query failed because of '"+err.Error()+"'", "error")
	}

	err = preparedStatement.QueryRow("wsrep_ready").Scan(&columnName, &galeraStatus.Node.Ready)
	if err != nil {
		config.ECSLogOutput("wsrep_ready query failed because of '"+err.Error()+"'", "error")
	}

	err = preparedStatement.QueryRow("wsrep_last_committed").Scan(&columnName, &galeraStatus.Node.Seqno)
	if err != nil {
		config.ECSLogOutput("wsrep_last_committed query failed because of '"+err.Error()+"'", "error")
	}

	if strings.ToLower(galeraStatus.Cluster.Partition) == "primary" && galeraStatus.Node.State == "Synced" && galeraStatus.Node.Connected == "ON" && galeraStatus.Node.Ready == "ON" {
		galeraStatus.Cluster.Status = "healthy"
	} else {
		galeraStatus.Cluster.Status = "unhealthy"
	}

	return &galeraStatus, nil
}
