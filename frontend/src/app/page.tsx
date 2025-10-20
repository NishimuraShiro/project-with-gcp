"use client";

import { useState, useEffect } from "react";

interface Todo {
  id: number;
  title: string;
  description: string | null;
  completed: boolean;
  created_at: string;
  updated_at: string;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";

export default function Home() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTitle, setNewTitle] = useState("");
  const [newDescription, setNewDescription] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Todoリストを取得
  const fetchTodos = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_URL}/api/todos`);
      if (!response.ok) throw new Error("Failed to fetch todos");
      const data = await response.json();
      setTodos(data);
      setError("");
    } catch (err) {
      setError("Todoの取得に失敗しました");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTodos();
  }, []);

  // Todoを追加
  const addTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    try {
      const response = await fetch(`${API_URL}/api/todos`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: newTitle, description: newDescription }),
      });

      if (!response.ok) throw new Error("Failed to create todo");

      setNewTitle("");
      setNewDescription("");
      fetchTodos();
    } catch (err) {
      setError("Todoの追加に失敗しました");
      console.error(err);
    }
  };

  // Todoの完了状態を切り替え
  const toggleTodo = async (id: number, completed: boolean) => {
    try {
      const response = await fetch(`${API_URL}/api/todos/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ completed: !completed }),
      });

      if (!response.ok) throw new Error("Failed to update todo");
      fetchTodos();
    } catch (err) {
      setError("Todoの更新に失敗しました");
      console.error(err);
    }
  };

  // Todoを削除
  const deleteTodo = async (id: number) => {
    if (!confirm("このTodoを削除しますか？")) return;

    try {
      const response = await fetch(`${API_URL}/api/todos/${id}`, {
        method: "DELETE",
      });

      if (!response.ok) throw new Error("Failed to delete todo");
      fetchTodos();
    } catch (err) {
      setError("Todoの削除に失敗しました");
      console.error(err);
    }
  };

  return (
    <div className="min-h-screen py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold text-center mb-8 text-gray-800">
          Todo App
        </h1>

        {error && (
          <div className="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {/* Todo追加フォーム */}
        <form onSubmit={addTodo} className="mb-8 bg-white p-6 rounded-lg shadow-md">
          <div className="mb-4">
            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
              タイトル
            </label>
            <input
              type="text"
              id="title"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Todoのタイトルを入力"
              required
            />
          </div>
          <div className="mb-4">
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              説明（オプション）
            </label>
            <textarea
              id="description"
              value={newDescription}
              onChange={(e) => setNewDescription(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Todoの説明を入力"
              rows={3}
            />
          </div>
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors font-medium"
          >
            追加
          </button>
        </form>

        {/* Todoリスト */}
        {loading ? (
          <div className="text-center py-8 text-gray-500">読み込み中...</div>
        ) : todos.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            Todoがありません。上のフォームから追加してください。
          </div>
        ) : (
          <div className="space-y-4">
            {todos.map((todo) => (
              <div
                key={todo.id}
                className={`bg-white p-6 rounded-lg shadow-md transition-all ${
                  todo.completed ? "opacity-60" : ""
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4 flex-1">
                    <input
                      type="checkbox"
                      checked={todo.completed}
                      onChange={() => toggleTodo(todo.id, todo.completed)}
                      className="mt-1 w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <h3
                        className={`text-lg font-semibold mb-2 ${
                          todo.completed ? "line-through text-gray-500" : "text-gray-800"
                        }`}
                      >
                        {todo.title}
                      </h3>
                      {todo.description && (
                        <p className={`text-gray-600 mb-2 ${todo.completed ? "line-through" : ""}`}>
                          {todo.description}
                        </p>
                      )}
                      <p className="text-xs text-gray-400">
                        作成日時: {new Date(todo.created_at).toLocaleString("ja-JP")}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => deleteTodo(todo.id)}
                    className="ml-4 text-red-600 hover:text-red-800 font-medium transition-colors"
                  >
                    削除
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
