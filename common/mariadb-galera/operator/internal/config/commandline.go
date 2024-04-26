package config

import (
	"flag"
	"fmt"
	"os"
)

type CmdLineFlags struct {
	DBUser           *string
	DBPassword       *string
	DBHost           *string
	DBPort           *string
	DBName           *string
	DBSocket         *string
	DBConnectionType *string
	StatusFile       *string
	LogEnable        *bool
	LogBuildInfo     *bool
	LogStackTrace    *bool
	LogLevel         *string
	Version          *bool
	BuildInfo        *bool
}

var (
	Options        CmdLineFlags
	CmdLineOptions = ParseCmdLine()
	UserHome       string
	err            error
)

func ParseCmdLine() CmdLineFlags {
	UserHome, err = os.UserHomeDir()
	if err != nil {
		fmt.Println("could not get the user home directory")
		os.Exit(1)
	}

	Options.DBUser = flag.String("dbuser", "monitor", "database user")
	Options.DBPassword = flag.String("dbpassword", "password", "database password")
	Options.DBHost = flag.String("dbhost", "localhost", "database network host")
	Options.DBPort = flag.String("dbport", "3306", "database network port")
	Options.DBName = flag.String("dbname", "mysql", "database name")
	Options.DBSocket = flag.String("dbsocket", "/opt/mariadb/run/mariadbd.sock", "database socket")
	Options.DBConnectionType = flag.String("dbconnectiontype", "", "socket or host")
	Options.StatusFile = flag.String("statusfile", UserHome+"/galerastatus.json", "status file location")
	Options.LogEnable = flag.Bool("logenable", true, "display structured log events")
	Options.LogBuildInfo = flag.Bool("logbuildinfo", false, "add build information to log output")
	Options.LogStackTrace = flag.Bool("logstacktrace", false, "add stacktrace to log output")
	Options.LogLevel = flag.String("loglevel", "error", "debug, info, warning, error, panic, fatal")
	Options.Version = flag.Bool("version", false, "display galerastatus version")
	Options.BuildInfo = flag.Bool("buildinfo", false, "display galerastatus build information")
	flag.Parse()

	return Options
}
