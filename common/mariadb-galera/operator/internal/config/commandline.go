package config

import (
	"flag"
)

type CmdLineFlags struct {
	DBUser           *string
	DBPassword       *string
	DBHost           *string
	DBPort           *string
	DBName           *string
	DBSocket         *string
	DBConnectionType *string
	LogOutput        *bool
	LogLevel         *string
	Version          *bool
	BuildInfo        *bool
}

var (
	Options        CmdLineFlags
	CmdLineOptions = ParseCmdLine()
)

func ParseCmdLine() CmdLineFlags {
	Options.DBUser = flag.String("dbuser", "monitor", "database user")
	Options.DBPassword = flag.String("dbpassword", "password", "database password")
	Options.DBHost = flag.String("dbhost", "localhost", "database network host")
	Options.DBPort = flag.String("dbport", "3306", "database network port")
	Options.DBName = flag.String("dbname", "mysql", "database name")
	Options.DBSocket = flag.String("dbsocket", "/opt/mariadb/run/mariadbd.sock", "database socket")
	Options.DBConnectionType = flag.String("dbconnectiontype", "", "socket or host")
	Options.LogOutput = flag.Bool("logoutput", false, "display structured log events")
	Options.LogLevel = flag.String("loglevel", "info", "trace, debug, info, warning, error, fatal, panic")
	Options.Version = flag.Bool("version", false, "display galerastatus version")
	Options.BuildInfo = flag.Bool("buildinfo", false, "display galerastatus build information")
	flag.Parse()

	return Options
}
