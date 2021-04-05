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
		if info.Mode().IsRegular() && filepath.Base(path) == "Chart.yaml" {
			buf, err := ioutil.ReadFile(path)
			must(err)
			chart := chartData{Path: filepath.Dir(path)}
			must(yaml.Unmarshal(buf, &chart))

			if len(chart.Dependencies) > 0 {
				for _, dep := range chart.Dependencies {
					dependency{chart, dep}.SerializeTo(os.Stdout)
				}
			} else {
				buf, err := ioutil.ReadFile(filepath.Join(chart.Path, "requirements.yaml"))
				if os.IsNotExist(err) {
					return nil
				}
				must(err)
				var reqs requirementsData
				must(yaml.Unmarshal(buf, &reqs))
				for _, dep := range reqs.Dependencies {
					dependency{chart, dep}.SerializeTo(os.Stdout)
				}
			}
		}
		return nil
	}))
}

type chartData struct {
	Path         string    `yaml:"-" json:"path"`
	Name         string    `yaml:"name" json:"name"`
	Version      string    `yaml:"version" json:"version"`
	Dependencies []depData `yaml:"dependencies" json:"-"`
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
	Parent     chartData `json:"parent"`
	Dependency depData   `json:"dependency"`
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
