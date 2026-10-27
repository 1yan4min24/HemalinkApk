<?php

namespace App\Http\Controllers\Api;

use App\Events\StockRequestSubmitted;
use App\Events\StockRequestUpdated;
use App\Http\Controllers\Controller;
use App\Http\Resources\StockRequestResource;
use App\Models\BloodStock;
use App\Models\StockRequest;
use App\Services\StockService;
use App\Support\BloodUtils;
use App\Support\Realtime;
use DomainException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

/** Pengajuan pengambilan darah langsung dari stok PMI. */
class StockRequestController extends Controller
{
    /** Pengajuan milik user yang login. */
    public function mine(Request $request)
    {
        StockService::expireOverdue();

        return StockRequestResource::collection(
            StockRequest::with('user')
                ->where('user_id', $request->user()->id)
                ->orderByDesc('id')
                ->get()
        );
    }

    /** Admin: semua pengajuan. */
    public function all()
    {
        StockService::expireOverdue();

        return StockRequestResource::collection(
            StockRequest::with('user')->orderByDesc('id')->get()
        );
    }

    /** Kirim pengajuan (multipart/form-data, field "attachment" = foto surat RS). */
    public function store(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'blood_type' => ['required', Rule::in(BloodUtils::TYPES)],
            'bags' => 'required|integer|min:1|max:100',
            'patient_name' => 'required|string|max:150',
            'hospital' => 'required|string|max:200',
            'reason' => 'required|string|max:500',
            'letter_no' => 'required|string|max:100',
            'attachment' => 'required|file|image|max:2048',
            'attachment_name' => 'nullable|string|max:200',
        ]);

        $file = $request->file('attachment');
        $path = $file->store('stock-attachments');

        try {
            $sr = DB::transaction(function () use ($data, $user, $path, $file) {
                $type = $data['blood_type'];
                $bags = (int) $data['bags'];

                $stock = BloodStock::where('blood_type', $type)->lockForUpdate()->firstOrFail();
                $available = (int) $stock->quantity;
                if ($available <= 0) {
                    abort(422, "Stok golongan $type sedang kosong.");
                }
                if ($bags > $available) {
                    abort(422, "Stok golongan $type hanya tersisa $available kantong.");
                }

                // Pengaju pertama langsung "mengunci" kantong darahnya.
                StockService::adjust(
                    $type,
                    -$bags,
                    $user->name,
                    'Pengajuan darah untuk pasien ' . trim($data['patient_name'])
                );

                return StockRequest::create([
                    'user_id' => $user->id,
                    'requester_phone' => $user->phone,
                    'blood_type' => $type,
                    'bags' => $bags,
                    'patient_name' => trim($data['patient_name']),
                    'hospital' => trim($data['hospital']),
                    'reason' => trim($data['reason']),
                    'letter_no' => trim($data['letter_no']),
                    'attachment_path' => $path,
                    'attachment_name' => $data['attachment_name'] ?? $file->getClientOriginalName(),
                    'status' => StockRequest::PROCESSING,
                    'admin_note' => '',
                ]);
            });
        } catch (\Throwable $e) {
            Storage::delete($path); // jangan tinggalkan file yatim
            throw $e;
        }

        $sr->load('user');
        Realtime::send(new StockRequestSubmitted($sr));

        return new StockRequestResource($sr);
    }

    /** Foto bukti rekomendasi (pemilik atau admin). */
    public function attachment(Request $request, StockRequest $stockRequest)
    {
        $user = $request->user();
        abort_unless($user->isAdmin() || (int) $stockRequest->user_id === (int) $user->id, 403, 'Tidak diizinkan.');
        abort_unless($stockRequest->attachment_path && Storage::exists($stockRequest->attachment_path), 404, 'Bukti tidak ditemukan.');

        return Storage::response($stockRequest->attachment_path);
    }

    // ---------- aksi admin ----------

    /** Setujui: stok tetap tertahan untuk pemohon. Body: {note?} */
    public function approve(Request $request, StockRequest $stockRequest)
    {
        $data = $request->validate(['note' => 'nullable|string|max:500']);

        $sr = DB::transaction(function () use ($stockRequest, $data) {
            $sr = StockRequest::lockForUpdate()->findOrFail($stockRequest->id);
            if ($sr->status !== StockRequest::PROCESSING) {
                abort(422, 'Pengajuan ini sudah ditanggapi.');
            }
            $sr->update([
                'status' => StockRequest::APPROVED,
                'approved_at' => now(),
                'admin_note' => trim($data['note'] ?? ''),
            ]);

            return $sr;
        });

        return $this->respond($sr);
    }

    /** Tolak: kantong dikembalikan ke stok. Body: {reason} (wajib) */
    public function reject(Request $request, StockRequest $stockRequest)
    {
        $data = $request->validate(['reason' => 'required|string|max:500']);

        $sr = DB::transaction(function () use ($stockRequest, $data) {
            $sr = StockRequest::with('user')->lockForUpdate()->findOrFail($stockRequest->id);
            if ($sr->status !== StockRequest::PROCESSING) {
                abort(422, 'Pengajuan ini sudah ditanggapi.');
            }
            $this->giveBack($sr, "Pengajuan ditolak ({$sr->user->name})");
            $sr->update([
                'status' => StockRequest::REJECTED,
                'admin_note' => trim($data['reason']),
                'resolved_at' => now(),
            ]);

            return $sr;
        });

        return $this->respond($sr);
    }

    /** Tandai darah sudah diambil di PMI. */
    public function complete(StockRequest $stockRequest)
    {
        $sr = DB::transaction(function () use ($stockRequest) {
            $sr = StockRequest::lockForUpdate()->findOrFail($stockRequest->id);
            if (!$sr->holdsStock()) {
                abort(422, 'Pengajuan ini sudah selesai atau dibatalkan.');
            }
            $sr->update(['status' => StockRequest::COMPLETED, 'resolved_at' => now()]);

            return $sr;
        });

        return $this->respond($sr);
    }

    /** Batalkan: kantong dikembalikan ke stok. Body: {note?} */
    public function cancel(Request $request, StockRequest $stockRequest)
    {
        $data = $request->validate(['note' => 'nullable|string|max:500']);

        $sr = DB::transaction(function () use ($stockRequest, $data) {
            $sr = StockRequest::with('user')->lockForUpdate()->findOrFail($stockRequest->id);
            if (!$sr->holdsStock()) {
                abort(422, 'Pengajuan ini sudah selesai atau dibatalkan.');
            }
            $this->giveBack($sr, "Pengajuan dibatalkan ({$sr->user->name})");
            $update = ['status' => StockRequest::CANCELLED, 'resolved_at' => now()];
            $note = trim($data['note'] ?? '');
            if ($note !== '') {
                $update['admin_note'] = $note;
            }
            $sr->update($update);

            return $sr;
        });

        return $this->respond($sr);
    }

    private function giveBack(StockRequest $sr, string $reason): void
    {
        try {
            StockService::adjust($sr->blood_type, $sr->bags, 'Admin PMI', $reason);
        } catch (DomainException $e) {
            abort(422, $e->getMessage());
        }
    }

    private function respond(StockRequest $sr)
    {
        $sr->load('user');
        Realtime::send(new StockRequestUpdated($sr));

        return new StockRequestResource($sr);
    }
}
