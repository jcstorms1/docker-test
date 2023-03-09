# Build process manager
FROM rust:latest as rust-binary
COPY /process_manager/ .
RUN cargo build --release --target=x86_64-unknown-linux-gnu

FROM ubuntu:latest as agent
# We extract the trace-agent from the agent and use a matching dogstatsd version
ARG AGENT_VERSION
# make the AGENT_VERSION arg mandatory
RUN : "${AGENT_VERSION:?AGENT_VERSION needs to be provided}"
RUN apt-get update
RUN apt-get install -y curl binutils zip
RUN mkdir datadog
COPY --from=rust-binary /target/x86_64-unknown-linux-gnu/release/process_manager datadog-aas/

# trace agent
RUN curl -LO https://apt.datadoghq.com/pool/d/da/datadog-agent_${AGENT_VERSION}_amd64.deb
RUN dpkg -i datadog-agent_${AGENT_VERSION}_amd64.deb
RUN mv opt/datadog-agent/embedded/bin/trace-agent datadog/
RUN dpkg -r datadog-agent
# dogstatsd
RUN curl -LO https://apt.datadoghq.com/pool/d/da/datadog-dogstatsd_${AGENT_VERSION}_amd64.deb
RUN dpkg -i datadog-dogstatsd_${AGENT_VERSION}_amd64.deb
RUN mv opt/datadog-dogstatsd/bin/dogstatsd datadog/
RUN dpkg -r datadog-dogstatsd
RUN rm *.deb

# strip binaries and zip folder for release
RUN strip /datadog-aas/*
RUN zip -r /datadog-aas.zip /datadog