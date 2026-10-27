<?php

namespace Database\Seeders;

use App\Models\BloodStock;
use App\Models\User;
use App\Support\BloodUtils;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Akun admin PMI. GANTI password sebelum dipakai sungguhan (set ADMIN_PASSWORD di .env).
        $admin = User::firstOrNew(['username' => 'admin']);
        $admin->forceFill([
            'name' => 'Admin PMI',
            'password' => env('ADMIN_PASSWORD', 'pmi12345'),
            'phone' => '',
            'blood_type' => '',
            'city' => 'Kota Ternate',
            'role' => 'admin',
        ])->save();

        foreach (BloodUtils::TYPES as $type) {
            BloodStock::firstOrCreate(['blood_type' => $type], ['quantity' => 0]);
        }
    }
}
