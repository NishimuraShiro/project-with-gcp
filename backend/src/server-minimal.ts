import express from 'express';

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString(), port: PORT });
});

app.get('/', (req, res) => {
  res.json({ message: 'Todo App Backend - Minimal Version', env: process.env.NODE_ENV });
});

app.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`Server started on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
