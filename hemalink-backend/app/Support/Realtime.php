<?php

namespace App\Support;

/** Kirim event broadcast tanpa menggagalkan request bila Reverb belum jalan. */
class Realtime
{
    public static function send(object $event, bool $toOthers = false): void
    {
        try {
            $pending = broadcast($event);
            if ($toOthers) {
                $pending->toOthers();
            }
            unset($pending); // dispatch terjadi saat objek dilepas, tetap di dalam try
        } catch (\Throwable $e) {
            report($e);
        }
    }
}
