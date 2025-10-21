import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { initDatabase } from './config/database';
import todoRoutes from './routes/todos';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// ヘルスチェック
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/todos', todoRoutes);

// エラーハンドリング
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// データベース初期化とサーバー起動
async function startServer() {
  try {
    // データベース初期化（失敗してもサーバーは起動する）
    try {
      await initDatabase();
      console.log('Database initialized successfully');
    } catch (dbError) {
      console.error('Database initialization warning:', dbError);
      console.log('Server will start without database connection');
    }

    // 0.0.0.0 でリッスン（Cloud Run要件）
    app.listen(Number(PORT), '0.0.0.0', () => {
      console.log(`Express server running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV}`);
      console.log(`DB_HOST: ${process.env.DB_HOST || 'not set'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
