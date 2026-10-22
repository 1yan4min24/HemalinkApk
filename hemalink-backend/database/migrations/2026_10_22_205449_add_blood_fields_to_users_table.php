<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('username')->unique()->after('name');
            $table->string('phone')->nullable()->after('email');
            $table->string('blood_type')->nullable()->after('phone');
            $table->string('city')->nullable()->after('blood_type');
            $table->integer('weight')->nullable()->after('city');
            $table->integer('height')->nullable()->after('weight');
            $table->enum('role', ['user', 'admin'])->default('user')->after('height');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['username', 'phone', 'blood_type', 'city', 'weight', 'height', 'role']);
        });
    }
};