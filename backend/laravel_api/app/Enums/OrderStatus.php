<?php

namespace App\Enums;

enum OrderStatus: string
{
    case WaitingPayment = 'WAITING_PAYMENT';
    case Paid = 'PAID';
    case Confirmed = 'CONFIRMED';
    case Preparing = 'PREPARING';
    case Ready = 'READY';
    case Completed = 'COMPLETED';
    case Rejected = 'REJECTED';
    case Cancelled = 'CANCELLED';

    public function label(): string
    {
        return match ($this) {
            self::WaitingPayment => 'Menunggu Pembayaran',
            self::Paid => 'Sudah Dibayar',
            self::Confirmed => 'Pesanan Dikonfirmasi',
            self::Preparing => 'Sedang Diproses',
            self::Ready => 'Siap Diambil',
            self::Completed => 'Selesai',
            self::Rejected => 'Ditolak',
            self::Cancelled => 'Dibatalkan',
        };
    }

    public function isFinal(): bool
    {
        return in_array($this, [self::Completed, self::Rejected, self::Cancelled], true);
    }

    public function isActive(): bool
    {
        return ! $this->isFinal();
    }

    /**
     * @return array<int, self>
     */
    public function allowedTransitions(): array
    {
        return match ($this) {
            self::WaitingPayment => [self::Paid, self::Cancelled],
            self::Paid => [self::Confirmed, self::Rejected],
            self::Confirmed => [self::Preparing],
            self::Preparing => [self::Ready],
            self::Ready => [self::Completed],
            self::Completed, self::Rejected, self::Cancelled => [],
        };
    }

    public function canTransitionTo(self $next): bool
    {
        return in_array($next, $this->allowedTransitions(), true);
    }
}
