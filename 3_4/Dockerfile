FROM docker:29.9.3-cli-alpine3.24

WORKDIR /app

COPY . .

RUN chmod +x ./builder.sh

ENTRYPOINT ["./builder.sh"]
