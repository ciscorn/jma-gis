# mapbox/tippecanoe (vector tile builder)

FROM alpine:latest

RUN apk update && apk --update-cache add g++ musl-dev make git bash sqlite-dev zlib-dev
RUN git clone https://github.com/felt/tippecanoe.git && cd tippecanoe && make -j && make install

CMD ["tippecanoe"]
