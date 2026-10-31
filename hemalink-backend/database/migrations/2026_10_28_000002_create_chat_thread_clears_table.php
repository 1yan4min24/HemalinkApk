<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** "Hapus percakapan untuk saya": penanda per pengguna, pesan asli tidak dihapus. */
    public function up(): void
    {
        Schema::create('chat_thread_clears', function (Blueprint $table) {
            $table->id();
            $table->foreignId('chat_thread_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('cleared_message_id')->default(0); // pesan <= ini disembunyikan
            $table->boolean('hidden')->default(true);                     // percakapan disembunyikan dari daftar
            $table->timestamps();
            $table->unique(['chat_thread_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_thread_clears');
    }
};
