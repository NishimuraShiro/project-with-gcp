// server.js - Express Backend for Todo App
const express = require("express");
const cors = require("cors");
const mysql = require("mysql2/promise");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// MySQL接続プールの作成
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "todo_db",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// テーブル作成（初回実行時）
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS todos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        completed BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log("Database initialized successfully");
  } catch (error) {
    console.error("Database initialization error:", error);
  }
}

initDatabase();

// ヘルスチェック
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date().toISOString() });
});

// 全てのTodoを取得
app.get("/api/todos", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM todos ORDER BY created_at DESC"
    );
    res.json(rows);
  } catch (error) {
    console.error("Error fetching todos:", error);
    res.status(500).json({ error: "Failed to fetch todos" });
  }
});

// 特定のTodoを取得
app.get("/api/todos/:id", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM todos WHERE id = ?", [
      req.params.id
    ]);

    if (rows.length === 0) {
      return res.status(404).json({ error: "Todo not found" });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error("Error fetching todo:", error);
    res.status(500).json({ error: "Failed to fetch todo" });
  }
});

// 新しいTodoを作成
app.post("/api/todos", async (req, res) => {
  const { title, description } = req.body;

  if (!title || title.trim() === "") {
    return res.status(400).json({ error: "Title is required" });
  }

  try {
    const [result] = await pool.query(
      "INSERT INTO todos (title, description) VALUES (?, ?)",
      [title, description || ""]
    );

    const [newTodo] = await pool.query("SELECT * FROM todos WHERE id = ?", [
      result.insertId
    ]);

    res.status(201).json(newTodo[0]);
  } catch (error) {
    console.error("Error creating todo:", error);
    res.status(500).json({ error: "Failed to create todo" });
  }
});

// Todoを更新
app.put("/api/todos/:id", async (req, res) => {
  const { title, description, completed } = req.body;
  const { id } = req.params;

  try {
    const updates = [];
    const values = [];

    if (title !== undefined) {
      updates.push("title = ?");
      values.push(title);
    }
    if (description !== undefined) {
      updates.push("description = ?");
      values.push(description);
    }
    if (completed !== undefined) {
      updates.push("completed = ?");
      values.push(completed);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    values.push(id);

    await pool.query(
      `UPDATE todos SET ${updates.join(", ")} WHERE id = ?`,
      values
    );

    const [updatedTodo] = await pool.query("SELECT * FROM todos WHERE id = ?", [
      id
    ]);

    if (updatedTodo.length === 0) {
      return res.status(404).json({ error: "Todo not found" });
    }

    res.json(updatedTodo[0]);
  } catch (error) {
    console.error("Error updating todo:", error);
    res.status(500).json({ error: "Failed to update todo" });
  }
});

// Todoを削除
app.delete("/api/todos/:id", async (req, res) => {
  try {
    const [result] = await pool.query("DELETE FROM todos WHERE id = ?", [
      req.params.id
    ]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Todo not found" });
    }

    res.json({ message: "Todo deleted successfully" });
  } catch (error) {
    console.error("Error deleting todo:", error);
    res.status(500).json({ error: "Failed to delete todo" });
  }
});

// 全てのTodoを削除（オプション）
app.delete("/api/todos", async (req, res) => {
  try {
    await pool.query("DELETE FROM todos");
    res.json({ message: "All todos deleted successfully" });
  } catch (error) {
    console.error("Error deleting all todos:", error);
    res.status(500).json({ error: "Failed to delete todos" });
  }
});

// エラーハンドリング
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});

app.listen(PORT, () => {
  console.log(`Express server running on port ${PORT}`);
});
