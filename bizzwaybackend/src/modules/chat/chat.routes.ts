import { Router } from 'express';
import { z } from 'zod';

import type { Env } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { ChatModel } from '../../models/Chat.js';
import { MessageModel } from '../../models/Message.js';
import { CreateChatSchema, SendMessageSchema } from './chat.schemas.js';

const IdParam = z.object({ id: z.string().min(10) });

export function chatRouter(env: Env) {
  const r = Router();

  r.post('/chats', requireAuth(env), async (req, res, next) => {
    try {
      const body = CreateChatSchema.parse(req.body);
      const me = req.auth!.sub;
      const other = body.participantUserId;
      const participants = [me, other].sort();

      const existing = await ChatModel.findOne({
        type: body.type,
        participants: { $all: participants, $size: 2 },
      });
      if (existing) return res.json({ id: existing._id.toString() });

      const chat = await ChatModel.create({
        type: body.type,
        participants,
        lastMessageAt: new Date(),
      });
      return res.status(201).json({ id: chat._id.toString() });
    } catch (e) {
      return next(e);
    }
  });

  r.get('/chats', requireAuth(env), async (req, res) => {
    const me = req.auth!.sub;
    const chats = await ChatModel.find({ participants: me }).sort({ lastMessageAt: -1 }).limit(50);
    return res.json(
      chats.map((c) => ({
        id: c._id.toString(),
        type: c.type,
        participants: c.participants.map((p) => p.toString()),
        lastMessageAt: c.lastMessageAt,
      })),
    );
  });

  r.get('/chats/:id/messages', requireAuth(env), async (req, res) => {
    const { id } = IdParam.parse(req.params);
    const me = req.auth!.sub;

    const chat = await ChatModel.findById(id);
    if (!chat) return res.status(404).json({ error: 'not_found' });
    if (!chat.participants.map((p) => p.toString()).includes(me)) {
      return res.status(403).json({ error: 'forbidden' });
    }

    const list = await MessageModel.find({ chatId: id }).sort({ createdAt: -1 }).limit(100);
    return res.json(
      list
        .reverse()
        .map((m) => ({
          id: m._id.toString(),
          chatId: m.chatId.toString(),
          senderId: m.senderId.toString(),
          text: m.text,
          createdAt: m.createdAt,
        })),
    );
  });

  r.post('/chats/:id/messages', requireAuth(env), async (req, res, next) => {
    try {
      const { id } = IdParam.parse(req.params);
      const body = SendMessageSchema.parse(req.body);
      const me = req.auth!.sub;

      const chat = await ChatModel.findById(id);
      if (!chat) return res.status(404).json({ error: 'not_found' });
      if (!chat.participants.map((p) => p.toString()).includes(me)) {
        return res.status(403).json({ error: 'forbidden' });
      }

      const msg = await MessageModel.create({
        chatId: id,
        senderId: me,
        text: body.text,
        readBy: [me],
      });

      await ChatModel.updateOne(
        { _id: id },
        { $set: { lastMessageAt: new Date() } },
      );

      return res.status(201).json({ id: msg._id.toString() });
    } catch (e) {
      return next(e);
    }
  });

  return r;
}

