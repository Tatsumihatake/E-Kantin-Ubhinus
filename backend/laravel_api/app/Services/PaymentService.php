<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentService
{
    public function __construct(private readonly OrderService $orderService) {}

    public function start(Order $order, User $customer): Payment
    {
        if ($order->customer_id !== $customer->id) {
            abort(403, 'Anda tidak memiliki kewenangan untuk membayar pesanan ini.');
        }

        if ($order->status !== OrderStatus::WaitingPayment) {
            abort(409, 'Pesanan tidak berada pada status menunggu pembayaran.');
        }

        $alreadyPaid = $order->payments()->where('status', PaymentStatus::Success)->exists();

        if ($alreadyPaid) {
            abort(409, 'Pesanan sudah dibayar.');
        }

        $payment = $order->payments()->create([
            'method' => 'QRIS',
            'amount' => $order->total,
            'status' => PaymentStatus::Pending,
            'reference' => 'MOCK-'.Str::upper(Str::random(10)),
        ]);

        return $payment->load('order');
    }

    public function simulate(Payment $payment, string $result): Payment
    {
        if (app()->environment('production')) {
            abort(403, 'Endpoint simulasi tidak tersedia pada production.');
        }

        return DB::transaction(function () use ($payment, $result): Payment {
            $locked = Payment::query()->lockForUpdate()->findOrFail($payment->id);

            if ($locked->status !== PaymentStatus::Pending) {
                abort(409, 'Percobaan pembayaran ini sudah memiliki hasil akhir.');
            }

            $order = $locked->order()->lockForUpdate()->firstOrFail();

            if ($order->status !== OrderStatus::WaitingPayment) {
                abort(409, 'Pesanan tidak lagi menunggu pembayaran.');
            }

            if ($result === 'success') {
                $locked->update([
                    'status' => PaymentStatus::Success,
                    'paid_at' => now(),
                ]);

                $this->orderService->transition(
                    $order,
                    OrderStatus::Paid,
                    $order->customer,
                    'Pembayaran simulasi QRIS berhasil.'
                );

                return $locked->fresh(['order']);
            }

            $locked->update([
                'status' => PaymentStatus::Failed,
            ]);

            return $locked->fresh(['order']);
        });
    }
}
