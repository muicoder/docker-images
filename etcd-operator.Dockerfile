FROM golang:alpine AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /alpine
RUN wget -qO- https://github.com/muicoder/etcd-operator/archive/refs/heads/main.tar.gz | tar -xz --strip-components=1
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags '-s -w -extldflags "-static"' -o /manager cmd/main.go

FROM alpine:latest
COPY --from=builder /manager /
USER 65532:65532
ENTRYPOINT ["/manager"]