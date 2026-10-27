<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Http\Resources\ChatMessageResource;
use App\Http\Resources\ChatThreadResource;
use App\Models\BloodRequest;
use App\Models\ChatMessage;
use App\Models\ChatThread;
use App\Support\Realtime;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    /** Daftar percakapan milik saya, yang terbaru di atas. */
    public function index(Request $request)
    {
        $me = $request->user()->id;
        $threads = ChatThread::with(['requester', 'donor', 'messages'])
            ->where(fn ($q) => $q->where('requester_id', $me)->orWhere('donor_id', $me))
            ->get()
            ->sortByDesc(fn ($t) => ($t->messages->last()?->created_at ?? $t->created_at)->timestamp)
            ->values();

        return ChatThreadResource::collection($threads);
    }

    /** Buka percakapan untuk sebuah permintaan (buat baru bila belum ada). Body: {request_id} */
    public function store(Request $request)
    {
        $data = $request->validate(['request_id' => 'required|integer|exists:blood_requests,id']);
        $me = $request->user();
        $req = BloodRequest::findOrFail($data['request_id']);

        if ((int) $req->user_id === (int) $me->id) {
            return response()->json(['message' => 'Anda tidak bisa memulai chat dengan permintaan sendiri.'], 422);
        }

        $thread = ChatThread::firstOrCreate(
            ['blood_request_id' => $req->id, 'donor_id' => $me->id],
            ['requester_id' => $req->user_id, 'blood_type' => $req->blood_type]
        );

        return new ChatThreadResource($thread->load(['requester', 'donor', 'messages']));
    }

    public function show(Request $request, ChatThread $chatThread)
    {
        abort_unless($chatThread->hasParticipant($request->user()->id), 403, 'Tidak diizinkan.');

        return new ChatThreadResource($chatThread->load(['requester', 'donor', 'messages']));
    }

    /** Kirim pesan. Body: {text} */
    public function sendMessage(Request $request, ChatThread $chatThread)
    {
        $me = $request->user();
        abort_unless($chatThread->hasParticipant($me->id), 403, 'Tidak diizinkan.');

        $data = $request->validate(['text' => 'required|string|max:2000']);

        $message = ChatMessage::create([
            'chat_thread_id' => $chatThread->id,
            'sender_id' => $me->id,
            'text' => trim($data['text']),
        ]);

        Realtime::send(new MessageSent($message), toOthers: true);

        return new ChatMessageResource($message);
    }
}
