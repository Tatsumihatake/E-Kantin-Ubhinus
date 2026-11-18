<?php

namespace Database\Factories;

use App\Enums\OrderStatus;
use App\Models\Canteen;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $subtotal = fake()->numberBetween(10000, 50000);

        return [
            'customer_id' => User::factory()->customer(),
            'canteen_id' => Canteen::factory(),
            'status' => OrderStatus::WaitingPayment,
            'subtotal' => $subtotal,
            'total' => $subtotal,
            'request' => null,
            'rejection_reason' => null,
        ];
    }

    public function withStatus(OrderStatus $status): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => $status,
        ]);
    }
}
