<?php

namespace App\Support;

use DateTimeInterface;
use Illuminate\Support\Carbon;

/** Format waktu untuk JSON: ISO 8601 UTC dengan akhiran Z, mis. 2026-10-27T15:39:27Z. */
class Dt
{
    public static function iso(DateTimeInterface|string|null $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        $c = $value instanceof DateTimeInterface ? Carbon::instance($value) : Carbon::parse($value);

        return $c->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
