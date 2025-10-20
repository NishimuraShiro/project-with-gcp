import { Router, Request, Response } from 'express';
import { ResultSetHeader, RowDataPacket } from 'mysql2';
import { pool } from '../config/database';
import { Todo, CreateTodoInput, UpdateTodoInput } from '../types/todo';

const router = Router();

// 全てのTodoを取得
router.get('/', async (req: Request, res: Response) => {
  try {
    const [todos] = await pool.query<RowDataPacket[]>('SELECT * FROM todos ORDER BY created_at DESC');
    res.json(todos);
  } catch (error) {
    console.error('Error fetching todos:', error);
    res.status(500).json({ error: 'Failed to fetch todos' });
  }
});

// 特定のTodoを取得
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const [todos] = await pool.query<RowDataPacket[]>('SELECT * FROM todos WHERE id = ?', [req.params.id]);

    if (todos.length === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }

    res.json(todos[0]);
  } catch (error) {
    console.error('Error fetching todo:', error);
    res.status(500).json({ error: 'Failed to fetch todo' });
  }
});

// Todoを作成
router.post('/', async (req: Request, res: Response) => {
  const { title, description }: CreateTodoInput = req.body;

  if (!title || title.trim() === '') {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    const [result] = await pool.query<ResultSetHeader>(
      'INSERT INTO todos (title, description) VALUES (?, ?)',
      [title, description || '']
    );

    const [newTodo] = await pool.query<RowDataPacket[]>('SELECT * FROM todos WHERE id = ?', [result.insertId]);

    res.status(201).json(newTodo[0]);
  } catch (error) {
    console.error('Error creating todo:', error);
    res.status(500).json({ error: 'Failed to create todo' });
  }
});

// Todoを更新
router.put('/:id', async (req: Request, res: Response) => {
  const { title, description, completed }: UpdateTodoInput = req.body;
  const { id } = req.params;

  try {
    const updates: string[] = [];
    const values: any[] = [];

    if (title !== undefined) {
      updates.push('title = ?');
      values.push(title);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      values.push(description);
    }
    if (completed !== undefined) {
      updates.push('completed = ?');
      values.push(completed);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(id);

    await pool.query<ResultSetHeader>(`UPDATE todos SET ${updates.join(', ')} WHERE id = ?`, values);

    const [updatedTodo] = await pool.query<RowDataPacket[]>('SELECT * FROM todos WHERE id = ?', [id]);

    if (updatedTodo.length === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }

    res.json(updatedTodo[0]);
  } catch (error) {
    console.error('Error updating todo:', error);
    res.status(500).json({ error: 'Failed to update todo' });
  }
});

// Todoを削除
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const [result] = await pool.query<ResultSetHeader>('DELETE FROM todos WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }

    res.json({ message: 'Todo deleted successfully' });
  } catch (error) {
    console.error('Error deleting todo:', error);
    res.status(500).json({ error: 'Failed to delete todo' });
  }
});

// 全てのTodoを削除
router.delete('/', async (req: Request, res: Response) => {
  try {
    await pool.query<ResultSetHeader>('DELETE FROM todos');
    res.json({ message: 'All todos deleted successfully' });
  } catch (error) {
    console.error('Error deleting all todos:', error);
    res.status(500).json({ error: 'Failed to delete todos' });
  }
});

export default router;
