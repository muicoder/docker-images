ARG VERSION
FROM muicoder/k3s:$VERSION AS k3s
FROM alpine:3.16 as base
COPY --from=k3s /k3s /
RUN apk add -U ca-certificates zstd tzdata && /k3s check-config || true
RUN mkdir -p /image/etc/ssl/certs /image/run /image/var/run /image/tmp /image/lib/modules /image/lib/firmware /image/var/lib/rancher/k3s/data/cni && \
   cp -afv  /var/lib/rancher/k3s/data/current/* /image && \
    for FILE in cni $(/image/bin/find /image/bin -lname cni -printf "%f\n"); do ln -s /bin/cni /image/var/lib/rancher/k3s/data/cni/$FILE; done && \
    echo "root:x:0:0:root:/:/bin/sh" > /image/etc/passwd && \
    echo "root:x:0:" > /image/etc/group && \
    cp /etc/ssl/certs/ca-certificates.crt /image/etc/ssl/certs/ca-certificates.crt

FROM scratch as collect
ARG OEM
ARG VERSION
ARG DRONE_TAG="v$VERSION+$OEM"
COPY --from=base /image /
COPY --from=base /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=k3s /k9s /bin
RUN mkdir -p /etc && \
    echo 'hosts: files dns' > /etc/nsswitch.conf && \
    echo "PRETTY_NAME=\"K3s ${DRONE_TAG}\"" > /etc/os-release && \
    chmod 1777 /tmp

FROM scratch
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
COPY --from=collect / /
ENV PATH="/var/lib/rancher/k3s/data/cni:$PATH:/bin/aux"
ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"
ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
