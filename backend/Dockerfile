FROM node:20-alpine

WORKDIR /app

# 依存関係をインストール
COPY package*.json ./

# ソースコードをコピー
COPY . .

EXPOSE 8080

# デフォルトコマンド（docker-compose.ymlでオーバーライド可能）
CMD ["sh", "-c", "npm install && npm run dev"]
