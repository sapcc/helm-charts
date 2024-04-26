package config

import (
	"fmt"
	"os"

	"go.elastic.co/ecszap"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"k8s.io/component-base/version"
)

var (
	LogEnable       *bool   = CmdLineOptions.LogEnable
	LogBuildInfo    *bool   = CmdLineOptions.LogBuildInfo
	LogStackTrace   *bool   = CmdLineOptions.LogStackTrace
	MinimumLogLevel *string = CmdLineOptions.LogLevel
	loglevel        zap.AtomicLevel
	logger          *zap.Logger
)

func Log() *zap.Logger {
	if *LogEnable {
		switch {
		case *MinimumLogLevel == "debug":
			loglevel = zap.NewAtomicLevelAt(zap.DebugLevel)
		case *MinimumLogLevel == "info":
			loglevel = zap.NewAtomicLevelAt(zap.InfoLevel)
		case *MinimumLogLevel == "warning":
			loglevel = zap.NewAtomicLevelAt(zap.WarnLevel)
		case *MinimumLogLevel == "error":
			loglevel = zap.NewAtomicLevelAt(zap.ErrorLevel)
		case *MinimumLogLevel == "panic":
			loglevel = zap.NewAtomicLevelAt(zap.PanicLevel)
		case *MinimumLogLevel == "fatal":
			loglevel = zap.NewAtomicLevelAt(zap.FatalLevel)
		default:
			fmt.Printf("%s is a not a valid log level\n", *MinimumLogLevel)
			os.Exit(1)
		}
	}

	stdout := zapcore.AddSync(os.Stdout)
	ecsEncoderConfig := ecszap.EncoderConfig{
		EncodeLevel:      zapcore.LowercaseLevelEncoder,
		EncodeDuration:   zapcore.MillisDurationEncoder,
		EncodeCaller:     ecszap.ShortCallerEncoder,
		EnableCaller:     true,
		EnableStackTrace: *LogStackTrace,
	}
	core := ecszap.NewCore(ecsEncoderConfig, stdout, loglevel)

	if *LogStackTrace {
		logger = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))
	} else {
		logger = zap.New(core, zap.AddCaller())
	}

	if *LogBuildInfo {
		logger = logger.With(zap.String("package.name", MetadataList.Name), zap.String("package.version", MetadataList.Version), zap.String("package.build_version", version.Get().GitCommit), zap.String("package.buildDate", version.Get().BuildDate), zap.String("package.architecture", version.Get().Platform))
	} else {
		logger = logger.With(zap.String("package.name", MetadataList.Name), zap.String("package.version", MetadataList.Version))
	}

	defer logger.Sync()
	return logger
}
