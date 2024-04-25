package config

import (
	"fmt"

	"k8s.io/component-base/version"
)

type Metadata struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	Version     string `yaml:"version"`
	GitCommitId string `yaml:"gitCommitId"`
	BuildDate   string `yaml:"buildDate"`
}

var (
	MetadataList Metadata
)

func BuildInfo() string {
	var buildinfo string = fmt.Sprintf("version: %s\ncommitId: %s\nbuildDate: %s\ngoVersion: %s\ncompiler: %s\nplatform: %s\n", MetadataList.Version, version.Get().GitCommit, version.Get().BuildDate, version.Get().GoVersion, version.Get().Compiler, version.Get().Platform)
	return buildinfo
}
