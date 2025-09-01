# Small enough but reliable; includes apt and ca-certificates
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    git \
    ca-certificates \
    pandoc \
    latexmk \
    biber \
    texlive-full \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Nice defaults for LaTeX builds
ENV TEXMFVAR=/root/texmf-var \
    TEXMFHOME=/root/texmf

WORKDIR /work
