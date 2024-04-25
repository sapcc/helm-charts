package database

import (
	"database/sql"
	"fmt"
	"sync"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/sapcc/helm-charts/common/mariadb-galera/operator/internal/config"
)

var mutex sync.RWMutex

func DB() *sql.DB {
	mutex.Lock()
	defer mutex.Unlock()

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", *config.CmdLineOptions.DBUser, *config.CmdLineOptions.DBPassword, *config.CmdLineOptions.DBHost, *config.CmdLineOptions.DBPort, *config.CmdLineOptions.DBName)
	conn, err := sql.Open("mysql", dsn)
	if err != nil {
		config.ECSLogOutput(err, "panic")
	}
	// defer conn.Close()

	conn.SetConnMaxLifetime(time.Minute * 3)
	conn.SetMaxOpenConns(10)
	conn.SetMaxIdleConns(10)

	// Open doesn't open a connection. Validate DSN data:
	err = conn.Ping()
	if err != nil {
		config.ECSLogOutput(err, "panic")
	}
	return conn
}
