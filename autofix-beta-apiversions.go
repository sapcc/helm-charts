///usr/bin/go run "$0" "$@"; exit $?
//
// This program can be used to replace deprecated API versions in your Helm templates automatically. Run as:
//
//   find $CHART_DIRECTORY/templates -type f -exec go run autofix-beta-apiversions.go {} \;
//
// Then review and commit any changes.

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"
)

var (
	kindRx       = regexp.MustCompile(`^\s*kind:\s*(\S+)\s*$`)
	apiVersionRx = regexp.MustCompile(`^\s*apiVersion:\s*(\S+)\s*$`)

	isDeprecatedAPIVersion = map[string]bool{
		"extensions/v1beta1": true,
		"apps/v1beta1":       true,
		"apps/v1beta2":       true,
	}

	correctAPIVersions = map[string]string{
		"NetworkPolicy":     "networking.k8s.io/v1",
		"PodSecurityPolicy": "policy/v1beta1",
		"DaemonSet":         "apps/v1",
		"Deployment":        "apps/v1",
		"StatefulSet":       "apps/v1",
		"Ingress":           "networking.k8s.io/v1beta1",
	}
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "usage: %s <yaml-template>\n", os.Args[0])
		os.Exit(1)
	}
	path := os.Args[1]

	contents, err := ioutil.ReadFile(path)
	must(err)
	lines := strings.SplitAfter(string(contents), "\n")

	for idx, line := range lines {
		apiVersionMatch := apiVersionRx.FindStringSubmatch(line)
		if apiVersionMatch == nil {
			continue
		}
		apiVersion := apiVersionMatch[1]
		if !isDeprecatedAPIVersion[apiVersion] {
			continue
		}
		kind := findNearbyKind(lines, idx)
		if kind == "" {
			fmt.Fprintf(os.Stderr, "%s:%d: cannot find Kind nearby\n", path, idx+1)
			os.Exit(1)
		}
		newAPIVersion := correctAPIVersions[kind]
		if newAPIVersion == "" {
			fmt.Fprintf(os.Stderr, "%s:%d: do not know how to fix %s/%s\n", path, idx+1, apiVersion, kind)
			os.Exit(1)
		}
		fmt.Printf("%s: autofixing %s/%s -> %s/%s\n", path, apiVersion, kind, newAPIVersion, kind)
		lines[idx] = strings.Replace(line, apiVersion, newAPIVersion, 1)
	}

	must(ioutil.WriteFile(path, []byte(strings.Join(lines, "")), 0666))
}

func must(err error) {
	if err != nil {
		panic(err.Error())
	}
}

func findNearbyKind(lines []string, idx int) string {
	for i := idx - 3; i <= idx+3; i++ {
		if i < 0 || i >= len(lines) {
			continue
		}
		match := kindRx.FindStringSubmatch(lines[i])
		if match != nil {
			return match[1]
		}
	}
	return ""
}
