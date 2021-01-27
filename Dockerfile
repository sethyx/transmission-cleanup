FROM alpine:edge

RUN apk add --no-cache transmission-cli
COPY . .

CMD /bin/sh cleanup.sh