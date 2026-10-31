<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Satu percakapan per pasangan pengguna. Percakapan ganda yang sudah ada
 * digabung: semua pesan dipindah ke percakapan tertua, dan topik (golongan
 * darah & permintaan) mengikuti percakapan yang paling baru.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function () {
            $keep = []; // "idKecil-idBesar" => id percakapan yang dipertahankan

            foreach (DB::table('chat_threads')->orderBy('id')->get() as $t) {
                $key = min($t->requester_id, $t->donor_id) . '-' . max($t->requester_id, $t->donor_id);

                if (!isset($keep[$key])) {
                    $keep[$key] = $t->id;
                    continue;
                }

                $keepId = $keep[$key];

                // 1) pindahkan pesan dulu (jangan ikut terhapus bersama percakapan ganda)
                DB::table('chat_messages')->where('chat_thread_id', $t->id)->update(['chat_thread_id' => $keepId]);
                // 2) hapus percakapan ganda (membebaskan indeks unik), 3) perbarui topik
                DB::table('chat_threads')->where('id', $t->id)->delete();
                DB::table('chat_threads')->where('id', $keepId)->update([
                    'requester_id' => $t->requester_id,
                    'donor_id' => $t->donor_id,
                    'blood_request_id' => $t->blood_request_id,
                    'blood_type' => $t->blood_type,
                    'updated_at' => now(),
                ]);
            }
        });
    }

    public function down(): void
    {
        // Penggabungan tidak bisa dibatalkan.
    }
};
