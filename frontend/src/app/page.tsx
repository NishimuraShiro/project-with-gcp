"use client";

import { useState, useEffect } from "react";

interface Todo {
  id: number;
  title: string;
  description: string;
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
        body: JSON.stringify({ title: newTitle, description: newDescription })
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
        body: JSON.stringify({ completed: !completed })
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
        method: "DELETE"
      });

      if (!response.ok) throw new Error("Failed to delete todo");
      fetchTodos();
    } catch (err) {
      setError("Todoの削除に失敗しました");
      console.error(err);
    }
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-8">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-4xl font-bold text-gray-800 mb-8 text-center">
          📝 Todo App
        </h1>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        {/* Todo追加フォーム */}
        <form
          onSubmit={addTodo}
          className="bg-white rounded-lg shadow-md p-6 mb-8"
        >
          <div className="mb-4">
            <input
              type="text"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="Todoのタイトル"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="mb-4">
            <textarea
              value={newDescription}
              onChange={(e) => setNewDescription(e.target.value)}
              placeholder="説明（オプション）"
              rows={3}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            type="submit"
            className="w-full bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 transition-colors font-semibold"
          >
            追加
          </button>
        </form>

        {/* Todoリスト */}
        <div className="space-y-3">
          {loading ? (
            <div className="text-center py-8">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
            </div>
          ) : todos.length === 0 ? (
            <div className="bg-white rounded-lg shadow-md p-8 text-center text-gray-500">
              Todoがありません。新しいTodoを追加してください！
            </div>
          ) : (
            todos.map((todo) => (
              <div
                key={todo.id}
                className="bg-white rounded-lg shadow-md p-5 hover:shadow-lg transition-shadow"
              >
                <div className="flex items-start gap-4">
                  <input
                    type="checkbox"
                    checked={todo.completed}
                    onChange={() => toggleTodo(todo.id, todo.completed)}
                    className="mt-1 h-5 w-5 text-blue-500 rounded focus:ring-2 focus:ring-blue-500 cursor-pointer"
                  />
                  <div className="flex-1">
                    <h3
                      className={`text-lg font-semibold ${
                        todo.completed
                          ? "line-through text-gray-400"
                          : "text-gray-800"
                      }`}
                    >
                      {todo.title}
                    </h3>
                    {todo.description && (
                      <p
                        className={`mt-1 ${
                          todo.completed ? "text-gray-400" : "text-gray-600"
                        }`}
                      >
                        {todo.description}
                      </p>
                    )}
                    <p className="text-xs text-gray-400 mt-2">
                      作成日:{" "}
                      {new Date(todo.created_at).toLocaleString("ja-JP")}
                    </p>
                  </div>
                  <button
                    onClick={() => deleteTodo(todo.id)}
                    className="text-red-500 hover:text-red-700 font-semibold px-3 py-1 rounded hover:bg-red-50 transition-colors"
                  >
                    削除
                  </button>
                </div>
              </div>
            ))
          )}
        </div>

        {/* 統計情報 */}
        {todos.length > 0 && (
          <div className="mt-8 bg-white rounded-lg shadow-md p-4 flex justify-around text-center">
            <div>
              <p className="text-2xl font-bold text-blue-500">{todos.length}</p>
              <p className="text-gray-600 text-sm">総数</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-green-500">
                {todos.filter((t) => t.completed).length}
              </p>
              <p className="text-gray-600 text-sm">完了</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-orange-500">
                {todos.filter((t) => !t.completed).length}
              </p>
              <p className="text-gray-600 text-sm">未完了</p>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
