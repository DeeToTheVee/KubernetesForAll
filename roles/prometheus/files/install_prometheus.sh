#!/bin/bash

cd /tmp

wget https://dl.google.com/go/go1.14.linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
export PATH=$PATH:/usr/local/go/bin

go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

if [ ! -d /tmp/prometheus-operator/kube-prometheus ]
then
  mkdir -p /tmp/prometheus-operator/kube-prometheus
fi

cd /tmp/prometheus-operator/kube-prometheus || exit 1

if [ ! -f /tmp/prometheus-operator/kube-prometheus/jsonnetfile.json ]
then
  jb init  # Creates the initial/empty `jsonnetfile.json`
fi

# Install the kube-prometheus dependency
jb install github.com/coreos/kube-prometheus/jsonnet/kube-prometheus@release-0.4 # Creates `vendor/` & `jsonnetfile.lock.json`, and fills in `jsonnetfile.json`


