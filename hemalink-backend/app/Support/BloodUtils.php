<?php

namespace App\Support;

/** Padanan dari BloodUtils & AppConstants di Flutter. */
class BloodUtils
{
    public const TYPES = ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];

    public const DONOR_INTERVAL_DAYS = 60;

    private static function abo(string $t): string
    {
        return str_replace(['+', '-'], '', $t);
    }

    public static function canDonate(string $donor, string $recipient): bool
    {
        $rhOk = !str_ends_with($donor, '+') || str_ends_with($recipient, '+');
        $d = self::abo($donor);
        $r = self::abo($recipient);
        $aboOk = $d === 'O' || $d === $r || $r === 'AB';

        return $rhOk && $aboOk;
    }
}
