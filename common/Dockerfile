FROM ubuntu:22.04 as builder
RUN apt-get update && apt-get install -y nasm

ARG ASM
COPY ${ASM} /boot.S
RUN echo "Building ${ASM}"
RUN nasm -f bin boot.S -o /boot.bin


FROM ubuntu:22.04
RUN mkdir -p /opt

RUN apt-get update && apt-get install -y socat qemu-system-x86

COPY ../common/qemu-wrap.sh /opt/entrypoint.sh
COPY --from=builder /boot.bin /tmp

ENTRYPOINT ["/opt/entrypoint.sh"]