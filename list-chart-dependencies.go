///usr/bin/go run "$0" "$@"; exit $?
//
// This program parses the dependencies in all Chart.yaml and requirements.yaml
// into a stream of JSON documents, for further analysis with jq(1). Run in the
// repo root without any arguments.

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

func main() {
	must(filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.Mode().IsRegular() {
			switch filepath.Base(path) {
			case "Chart.yaml":
				buf, err := ioutil.ReadFile(path)
				must(err)
				var data chartData
				must(yaml.Unmarshal(buf, &data))
				for _, dep := range data.Dependencies {
					dependency{filepath.Dir(path), dep}.SerializeTo(os.Stdout)
				}
			case "requirements.yaml":
				buf, err := ioutil.ReadFile(path)
				must(err)
				var data requirementsData
				must(yaml.Unmarshal(buf, &data))
				for _, dep := range data.Dependencies {
					dependency{filepath.Dir(path), dep}.SerializeTo(os.Stdout)
				}
			}
		}
		return nil
	}))
}

type chartData struct {
	Dependencies []depData `yaml:"dependencies"`
}

type requirementsData struct {
	Dependencies []depData `yaml:"dependencies"`
}

type depData struct {
	Name       string `json:"name" yaml:"name"`
	Repository string `json:"repository" yaml:"repository"`
	Version    string `json:"version" yaml:"version"`
}

type dependency struct {
	Parent     string  `json:"parent"`
	Dependency depData `json:"dependency"`
}

func (d dependency) SerializeTo(w io.Writer) {
	buf, err := json.Marshal(d)
	must(err)
	fmt.Fprintln(w, string(buf))
}

func must(err error) {
	if err != nil {
		panic(err.Error())
	}
}
