<?php

namespace Database\Factories;

use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\Payment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Payment>
 */
class PaymentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'method' => 'QRIS',
            'amount' => fake()->numberBetween(10000, 50000),
            'status' => PaymentStatus::Pending,
            'reference' => 'MOCK-'.fake()->unique()->numerify('######'),
            'paid_at' => null,
        ];
    }

    public function success(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => PaymentStatus::Success,
            'paid_at' => now(),
        ]);
    }
}
