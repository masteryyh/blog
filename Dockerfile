FROM node:21.6-alpine3.19 AS builder

LABEL maintainer="masteryyh"
LABEL description="Dockerfile for masteryyh's blog"

WORKDIR /build

COPY . .

RUN npm install npm -g && \
    npm install && \
    npm install hexo-cli -g && \
    hexo clean && hexo generate

FROM nginxinc/nginx-unprivileged:1.25.3-alpine3.18 AS server

WORKDIR /usr/share/nginx/html

COPY --from=builder /build/public/ .
