<?php

namespace Database\Factories;

use App\Models\Addon;
use App\Models\OrderItem;
use App\Models\OrderItemAddon;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<OrderItemAddon>
 */
class OrderItemAddonFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'order_item_id' => OrderItem::factory(),
            'addon_id' => Addon::factory(),
            'addon_name_snapshot' => ucfirst(fake()->word()),
            'addon_price' => fake()->numberBetween(1000, 5000),
            'quantity' => 1,
        ];
    }
}
