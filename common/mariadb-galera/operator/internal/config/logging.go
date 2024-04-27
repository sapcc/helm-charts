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
	LogEnable        *bool   = CmdLineOptions.LogEnable
	LogCaller        *bool   = CmdLineOptions.LogCaller
	LogStackTrace    *bool   = CmdLineOptions.LogStackTrace
	LogBuildInfo     *bool   = CmdLineOptions.LogBuildInfo
	MinimumLogLevel  *string = CmdLineOptions.LogLevel
	loglevel         zap.AtomicLevel
	logger           *zap.Logger
	stdout           zapcore.WriteSyncer = zapcore.AddSync(os.Stdout)
	ecsEncoderConfig                     = ecszap.EncoderConfig{
		EncodeLevel:      zapcore.LowercaseLevelEncoder,
		EncodeDuration:   zapcore.MillisDurationEncoder,
		EncodeCaller:     ecszap.ShortCallerEncoder,
		EnableCaller:     *LogCaller,
		EnableStackTrace: *LogStackTrace,
	}
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

	core := ecszap.NewCore(ecsEncoderConfig, stdout, loglevel)
	logger = zap.New(core, zap.AddStacktrace(zapcore.ErrorLevel))
	logger = logger.With(zap.String("package.name", MetadataList.Name), zap.String("package.version", MetadataList.Version))

	if *LogBuildInfo {
		logger = logger.With(zap.String("package.build_version", version.Get().GitCommit), zap.String("package.buildDate", version.Get().BuildDate), zap.String("package.architecture", version.Get().Platform))
	}

	defer logger.Sync()
	return logger
}

// Sets the minimum log level to info to log info messages even if the log level is set to a lower level.
// This is useful for logging startup messages and other important information
func LogInfo() *zap.Logger {
	infoLevel := zap.WrapCore(func(zapcore.Core) zapcore.Core {
		return ecszap.NewCore(ecsEncoderConfig, stdout, zap.NewAtomicLevelAt(zap.InfoLevel))
	})

	logger := Log().WithOptions(infoLevel)
	return logger
}
