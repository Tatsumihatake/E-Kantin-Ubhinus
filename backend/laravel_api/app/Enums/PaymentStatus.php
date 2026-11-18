<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case Pending = 'PENDING';
    case Success = 'SUCCESS';
    case Failed = 'FAILED';
    case Expired = 'EXPIRED';
    case Cancelled = 'CANCELLED';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Menunggu Pembayaran',
            self::Success => 'Berhasil',
            self::Failed => 'Gagal',
            self::Expired => 'Kedaluwarsa',
            self::Cancelled => 'Dibatalkan',
        };
    }
}
