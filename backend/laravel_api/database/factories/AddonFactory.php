<?php

namespace Database\Factories;

use App\Enums\SelectionRule;
use App\Models\Addon;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Addon>
 */
class AddonFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'product_id' => Product::factory(),
            'name' => ucfirst(fake()->word()),
            'price' => fake()->numberBetween(1000, 6000),
            'selection_rule' => SelectionRule::Optional,
            'is_available' => true,
        ];
    }

    public function required(): static
    {
        return $this->state(fn (array $attributes): array => [
            'selection_rule' => SelectionRule::Required,
        ]);
    }

    public function unavailable(): static
    {
        return $this->state(fn (array $attributes): array => [
            'is_available' => false,
        ]);
    }
}
