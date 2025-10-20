FROM node:20-alpine

WORKDIR /app

# 依存関係をインストール
COPY package*.json ./

# ソースコードをコピー
COPY . .

EXPOSE 3000

# デフォルトコマンド（起動時にnpm installを実行）
CMD ["sh", "-c", "npm install && npm run dev"]
