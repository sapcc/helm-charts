package config

import (
	"fmt"
	"os"

	"github.com/sirupsen/logrus"
)

var (
	LogOutput     *bool
	LogLevel      *string
	ErrorOccurred bool
)

func ActivateECSLog() *logrus.Logger {
	// map command line parameters to the related variables
	LogOutput = CmdLineOptions.LogOutput
	LogLevel = CmdLineOptions.LogLevel

	// activate ECS logging
	ecsLog := logrus.New()
	ecsLog.SetOutput(os.Stdout)
	ecsLog.ReportCaller = false

	if *LogOutput {
		switch {
		case *LogLevel == "trace":
			ecsLog.SetLevel(logrus.TraceLevel)
		case *LogLevel == "debug":
			ecsLog.SetLevel(logrus.DebugLevel)
		case *LogLevel == "info":
			ecsLog.SetLevel(logrus.InfoLevel)
		case *LogLevel == "warning":
			ecsLog.SetLevel(logrus.WarnLevel)
		case *LogLevel == "error":
			ecsLog.SetLevel(logrus.ErrorLevel)
		case *LogLevel == "fatal":
			ecsLog.SetLevel(logrus.FatalLevel)
		case *LogLevel == "panic":
			ecsLog.SetLevel(logrus.PanicLevel)
		default:
			fmt.Printf("%s is a not a valid log level\n", *LogLevel)
			os.Exit(1)
		}
	} else {
		ecsLog.SetLevel(logrus.ErrorLevel)
	}

	return ecsLog
}

func ECSLogOutput(message interface{}, loglevel string) {
	ecsLog := ActivateECSLog()

	switch message.(type) {
	case error:
		switch {
		case loglevel == "trace":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Trace(message)
		case loglevel == "debug":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Debug(message)
		case loglevel == "info":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Info(message)
		case loglevel == "warning":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Warn(message)
		case loglevel == "error":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Error(message)
			ErrorOccurred = true
		case loglevel == "fatal":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Fatal(message)
			ErrorOccurred = true
		case loglevel == "panic":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Panic(message)
			os.Exit(1)
		default:
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Panic(message)
			os.Exit(1)
		}
	case string:
		switch {
		case loglevel == "trace":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Trace(message)
		case loglevel == "debug":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Debug(message)
		case loglevel == "info":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Info(message)
		case loglevel == "warning":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Warn(message)
		case loglevel == "error":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Error(message)
			ErrorOccurred = true
		case loglevel == "fatal":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Fatal(message)
			ErrorOccurred = true
		case loglevel == "panic":
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Panic(message)
			os.Exit(1)
		default:
			ecsLog.WithField(MetadataList.Name+".version", MetadataList.Version).Panic(message)
			os.Exit(1)
		}
	}
}
