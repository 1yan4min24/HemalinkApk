<?php

namespace App\Events;

use App\Http\Resources\ChatMessageResource;
use App\Models\ChatMessage;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(public ChatMessage $message)
    {
        $this->message->loadMissing('thread');
    }

    public function broadcastOn(): array
    {
        $thread = $this->message->thread;
        $recipientId = (int) $this->message->sender_id === (int) $thread->requester_id
            ? $thread->donor_id
            : $thread->requester_id;

        return [
            new PrivateChannel('chat.' . $thread->id),     // layar chat yang sedang terbuka
            new PrivateChannel('user.' . $recipientId),    // daftar chat / notifikasi lawan bicara
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    public function broadcastWith(): array
    {
        return [
            'threadId' => (string) $this->message->chat_thread_id,
            'message' => (new ChatMessageResource($this->message))->resolve(),
        ];
    }
}
