<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Http\Resources\ChatMessageResource;
use App\Http\Resources\ChatThreadResource;
use App\Models\BloodRequest;
use App\Models\ChatMessage;
use App\Models\ChatThread;
use App\Models\ChatThreadClear;
use App\Support\Realtime;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    /** Muat relasi dan sembunyikan pesan yang sudah "dihapus" oleh pengguna ini. */
    private function forUser(ChatThread $thread, ?ChatThreadClear $clear): ChatThread
    {
        $thread->loadMissing(['requester', 'donor', 'messages']);
        if ($clear && $clear->cleared_message_id > 0) {
            $thread->setRelation(
                'messages',
                $thread->messages->filter(fn ($m) => $m->id > $clear->cleared_message_id)->values()
            );
        }

        return $thread;
    }

    private function clearOf(ChatThread $thread, int $userId): ?ChatThreadClear
    {
        return ChatThreadClear::where('chat_thread_id', $thread->id)->where('user_id', $userId)->first();
    }

    /** Daftar percakapan milik saya (yang tidak saya hapus), terbaru di atas. */
    public function index(Request $request)
    {
        $me = $request->user()->id;

        $threads = ChatThread::with(['requester', 'donor', 'messages'])
            ->where(fn ($q) => $q->where('requester_id', $me)->orWhere('donor_id', $me))
            ->get();

        $clears = ChatThreadClear::where('user_id', $me)->get()->keyBy('chat_thread_id');

        $threads = $threads
            ->filter(fn ($t) => !($clears->get($t->id)?->hidden ?? false))
            ->map(fn ($t) => $this->forUser($t, $clears->get($t->id)))
            ->sortByDesc(fn ($t) => ($t->messages->last()?->created_at ?? $t->created_at)->timestamp)
            ->values();

        return ChatThreadResource::collection($threads);
    }

    /** Buka percakapan dengan pemilik sebuah permintaan (memakai yang sudah ada bila pernah chat). Body: {request_id} */
    public function store(Request $request)
    {
        $data = $request->validate(['request_id' => 'required|integer|exists:blood_requests,id']);
        $me = $request->user();
        $req = BloodRequest::findOrFail($data['request_id']);

        if ((int) $req->user_id === (int) $me->id) {
            return response()->json(['message' => 'Anda tidak bisa memulai chat dengan permintaan sendiri.'], 422);
        }

        // Satu percakapan per pasangan pengguna (peran pemohon/pendonor boleh bertukar).
        $thread = ChatThread::where(fn ($q) => $q
                ->where('requester_id', $req->user_id)->where('donor_id', $me->id))
            ->orWhere(fn ($q) => $q
                ->where('requester_id', $me->id)->where('donor_id', $req->user_id))
            ->first();

        $topic = [
            'requester_id' => $req->user_id,
            'donor_id' => $me->id,
            'blood_request_id' => $req->id,
            'blood_type' => $req->blood_type,
        ];

        if ($thread) {
            $thread->update($topic); // topik percakapan mengikuti permintaan terbaru
        } else {
            $thread = ChatThread::create($topic);
        }

        // Bila sebelumnya saya hapus, tampilkan lagi (hanya pesan baru yang terlihat).
        ChatThreadClear::where('chat_thread_id', $thread->id)->where('user_id', $me->id)->update(['hidden' => false]);

        return new ChatThreadResource($this->forUser($thread, $this->clearOf($thread, $me->id)));
    }

    public function show(Request $request, ChatThread $chatThread)
    {
        $me = $request->user()->id;
        abort_unless($chatThread->hasParticipant($me), 403, 'Tidak diizinkan.');

        return new ChatThreadResource($this->forUser($chatThread, $this->clearOf($chatThread, $me)));
    }

    /** Hapus percakapan hanya untuk saya; lawan chat tetap melihatnya. */
    public function destroy(Request $request, ChatThread $chatThread): JsonResponse
    {
        $me = $request->user();
        abort_unless($chatThread->hasParticipant($me->id), 403, 'Tidak diizinkan.');

        $lastId = (int) ChatMessage::where('chat_thread_id', $chatThread->id)->max('id');

        ChatThreadClear::updateOrCreate(
            ['chat_thread_id' => $chatThread->id, 'user_id' => $me->id],
            ['cleared_message_id' => $lastId, 'hidden' => true]
        );

        return response()->json(['message' => 'Percakapan dihapus.']);
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

        // Pesan baru memunculkan kembali percakapan yang sempat dihapus (oleh siapa pun).
        ChatThreadClear::where('chat_thread_id', $chatThread->id)->update(['hidden' => false]);

        Realtime::send(new MessageSent($message), toOthers: true);

        return new ChatMessageResource($message);
    }
}
