<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BloodRequestController;
use App\Http\Controllers\Api\CariPendonorController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\DonorHistoryController;
use App\Http\Controllers\Api\StatsController;
use App\Http\Controllers\Api\StockController;
use App\Http\Controllers\Api\StockRequestController;
use App\Http\Middleware\EnsureAdmin;
use Illuminate\Support\Facades\Route;

Route::get('/ping', fn () => response()->json(['status' => 'ok', 'app' => 'HemaLink']));

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () {
    // Akun
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);

    // Stok (baca)
    Route::get('/stock', [StockController::class, 'show']);

    // Forum permintaan darah
    Route::get('/blood-requests', [BloodRequestController::class, 'index']);
    Route::post('/blood-requests', [BloodRequestController::class, 'store']);
    Route::delete('/blood-requests/{bloodRequest}', [BloodRequestController::class, 'destroy']);

    // Pengajuan darah ke PMI
    Route::get('/stock-requests', [StockRequestController::class, 'mine']);
    Route::post('/stock-requests', [StockRequestController::class, 'store']);
    Route::get('/stock-requests/{stockRequest}/attachment', [StockRequestController::class, 'attachment']);

    // Chat
    Route::get('/chat-threads', [ChatController::class, 'index']);
    Route::post('/chat-threads', [ChatController::class, 'store']);
    Route::get('/chat-threads/{chatThread}', [ChatController::class, 'show']);
    Route::post('/chat-threads/{chatThread}/messages', [ChatController::class, 'sendMessage']);

    // Riwayat donor
    Route::get('/donor-histories', [DonorHistoryController::class, 'index']);
    Route::post('/donor-histories', [DonorHistoryController::class, 'store']);
    Route::delete('/donor-histories/{donorHistory}', [DonorHistoryController::class, 'destroy']);

    // Cari pendonor
    Route::get('/cari-pendonor/{type}', [CariPendonorController::class, 'index']);

    // Khusus admin
    Route::middleware(EnsureAdmin::class)->prefix('admin')->group(function () {
        Route::get('/stats', [StatsController::class, 'index']);
        Route::put('/stock', [StockController::class, 'update']);
        Route::get('/stock-logs', [StockController::class, 'logs']);
        Route::get('/stock-requests', [StockRequestController::class, 'all']);
        Route::post('/stock-requests/{stockRequest}/approve', [StockRequestController::class, 'approve']);
        Route::post('/stock-requests/{stockRequest}/reject', [StockRequestController::class, 'reject']);
        Route::post('/stock-requests/{stockRequest}/complete', [StockRequestController::class, 'complete']);
        Route::post('/stock-requests/{stockRequest}/cancel', [StockRequestController::class, 'cancel']);
    });
});
