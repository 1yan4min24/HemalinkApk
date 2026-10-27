<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stock_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('requester_phone', 30)->default('');
            $table->string('blood_type', 3)->index();
            $table->unsignedSmallInteger('bags');
            $table->string('patient_name');
            $table->string('hospital');
            $table->text('reason');
            $table->string('letter_no')->default('');
            $table->string('attachment_path')->nullable();
            $table->string('attachment_name')->default('');
            // processing | approved | completed | rejected | cancelled
            $table->string('status', 15)->default('processing')->index();
            $table->text('admin_note')->nullable();
            $table->dateTime('approved_at')->nullable();
            $table->dateTime('resolved_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_requests');
    }
};
