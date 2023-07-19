HOST="10.42.0.149"


ssh $HOST " rm -rf ~/ring0; \
    mkdir -p ~/ring0/frp && \
    cd ~/ring0 && \
    wget https://github.com/fatedier/frp/releases/download/v0.51.0/frp_0.51.0_linux_amd64.tar.gz && \
    tar -zxvf frp_0.51.0_linux_amd64.tar.gz && \
    mv frp_0.51.0_linux_amd64/frpc ~/ring0/frp && \
    rm -rf frp_0.51.0_linux_amd64*"

scp -r ./level* ./common docker-compose.yml $HOST:~/ring0/
scp ./frpc.ini $HOST:~/ring0/frp

ssh $HOST "cd ~/ring0 && docker-compose up -d --build"

ssh $HOST "cd ~/ring0/frp && \
    killall frpc; \
    nohup ./frpc -c ./frpc.ini > ./frpc.log 2>&1 & disown"

echo "Deployed to $HOST, hopefully."