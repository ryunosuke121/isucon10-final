include env
# 変数定義 ------------------------

# SERVER_ID: env.sh内で定義

# 問題によって変わる変数
USER:=isucon
BIN_NAME:=bin/xsuportal
BUILD_DIR:=/home/isucon/webapp/golang
CMD_MAINGO:=cmd/xsuportal/main.go
SERVICE_NAME:=xsuportal-web-golang.service

DB_PATH:=/etc/mysql
#NGINX_PATH:=/etc/nginx
SYSTEMD_PATH:=/etc/systemd/system

#NGINX_LOG:=/var/log/nginx/access.log
# DB_SLOW_LOG:=/var/log/mysql/mariadb-slow.log

# メインで使うコマンド ------------------------

# サーバーの環境構築　ツールのインストール、gitまわりのセットアップ
.PHONY: setup
setup: install-tools git-setup

# 設定ファイルを取得してgit管理下に配置する
.PHONY: get-conf
get-conf: check-server-id get-db-conf get-service-file get-envsh

# リポジトリ内の設定ファイルをそれぞれ配置する
.PHONY: deploy-conf
deploy-conf: check-server-id deploy-db-conf deploy-service-file deploy-envsh

# ベンチマークを走らせる直前に実行する
.PHONY: bench
bench: check-server-id build deploy-conf restart

# 主要コマンドの構成要素 ------------------------
.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade
	sudo apt install -y git

	# Goのインストール
	wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
	sudo rm -rf /home/isucon/local/go
	tar -C /home/isucon/local -xzf go1.23.2.linux-amd64.tar.gz

	# alpとslpのインストール
	go install github.com/tkuchiki/alp/cmd/alp@latest
	go install github.com/tkuchiki/slp/cmd/slp@latest

	# pproteinのインストール
	wget https://github.com/kaz/pprotein/releases/download/v1.2.3/pprotein_1.2.3_linux_amd64.tar.gz
	tar -xzf pprotein_1.2.3_linux_amd64.tar.gz

.PHONY: git-setup
git-setup:
	git config --global user.email "isucon@example.com"
	git config --global user.name "isucon"

	ssh-keygen -t ed25519

.PHONY: check-server-id
check-server-id:
ifdef SERVER_ID
	@echo "SERVER_ID=$(SERVER_ID)"
else
	@echo "SERVER_ID is unset"
	@exit 1
endif

.PHONY: set-as-s1
set-as-s1:
	echo "SERVER_ID=s1" >> env.sh

.PHONY: set-as-s2
set-as-s2:
	echo "SERVER_ID=s2" >> env.sh

.PHONY: set-as-s3
set-as-s3:
	echo "SERVER_ID=s3" >> env.sh

.PHONY: get-db-conf
get-db-conf:
	sudo cp -R $(DB_PATH)/* ~/$(SERVER_ID)/etc/mysql
	sudo chown $(USER) -R ~/$(SERVER_ID)/etc/mysql

.PHONY: get-nginx-conf
get-nginx-conf:
	sudo cp -R $(NGINX_PATH)/* ~/$(SERVER_ID)/etc/nginx
	sudo chown $(USER) -R ~/$(SERVER_ID)/etc/nginx

.PHONY: get-service-file
get-service-file:
	sudo cp $(SYSTEMD_PATH)/$(SERVICE_NAME) ~/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME)
	sudo chown $(USER) ~/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME)

.PHONY: get-envsh
get-envsh:
	cp ~/env ~/$(SERVER_ID)/home/isucon/env

.PHONY: deploy-db-conf
deploy-db-conf:
	sudo cp -R ~/$(SERVER_ID)/etc/mysql/* $(DB_PATH)

.PHONY: deploy-nginx-conf
deploy-nginx-conf:
	sudo cp -R ~/$(SERVER_ID)/etc/nginx/* $(NGINX_PATH)

.PHONY: deploy-service-file
deploy-service-file:
	sudo cp ~/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME) $(SYSTEMD_PATH)/$(SERVICE_NAME)

.PHONY: deploy-envsh
deploy-envsh:
	cp ~/$(SERVER_ID)/home/isucon/env ~/env

.PHONY: build
build:
	cd $(BUILD_DIR); \
	go build -o $(BIN_NAME) $(CMD_MAINGO)

.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart $(SERVICE_NAME)
	sudo systemctl restart mysql
	# sudo systemctl restart nginx




