<?php

namespace Database\Factories;

use App\Models\Canteen;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'canteen_id' => Canteen::factory(),
            'category_id' => Category::factory(),
            'name' => ucfirst(fake()->words(2, true)),
            'description' => fake()->sentence(),
            'image_url' => null,
            'price' => fake()->numberBetween(8000, 30000),
            'is_available' => true,
        ];
    }

    public function unavailable(): static
    {
        return $this->state(fn (array $attributes): array => [
            'is_available' => false,
        ]);
    }
}
