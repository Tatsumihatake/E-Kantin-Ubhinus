<?php

namespace Database\Factories;

use App\Models\Canteen;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Canteen>
 */
class CanteenFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'seller_id' => User::factory()->seller(),
            'name' => 'Kantin '.fake()->lastName(),
            'description' => fake()->sentence(),
            'image_url' => null,
            'opening_hours' => [
                'monday_friday' => '07:00-16:00',
            ],
            'is_open' => true,
        ];
    }
}
