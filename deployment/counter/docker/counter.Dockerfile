FROM golang:1.14-alpine

COPY counter /app/counter

ENTRYPOINT ["/app/counter"]