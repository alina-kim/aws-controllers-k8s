
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# Build the manager binary
FROM golang:1.14.1 as builder

ARG work_dir=/github.com/aws/aws-controllers-k8s
WORKDIR $work_dir
# For building Go Module required
ENV GOPROXY=direct
ENV GO111MODULE=on
ENV GOARCH=amd64
ENV GOOS=linux
ENV CGO_ENABLED=0
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN  go mod download
# Copy the go source
# TODO: for now copy whole repository. Later once autogeneration is ready, need to determine which dependencies to take in
COPY . $work_dir/
# Build
RUN  go build -a -o $work_dir/bin/controller $work_dir/services/rds/cmd/controller/main.go


FROM amazonlinux:2
ARG work_dir=/github.com/aws/aws-controllers-k8s
WORKDIR /
COPY --from=builder $work_dir/bin/controller /bin/.
ENTRYPOINT ["/bin/controller"]
