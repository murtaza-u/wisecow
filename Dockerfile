FROM bash:5.2.32

# insalling dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk update && apk add --no-cache fortune cowsay netcat-openbsd curl

RUN mkdir /wisecow
WORKDIR /wisecow
COPY wisecow.sh .

# creating non-root user
RUN adduser --disabled-password --no-create-home srv
RUN chown -R srv /wisecow
USER srv

# health check
HEALTHCHECK CMD curl --fail http://localhost:4499/ || exit 1

EXPOSE 4499
ENTRYPOINT [ "./wisecow.sh" ]
