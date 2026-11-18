<?php

namespace Tests\Feature;

use App\Models\Addon;
use App\Models\Canteen;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_search_is_case_insensitive_and_matches_partial_name(): void
    {
        $product = Product::factory()->create(['name' => 'Ayam Geprek Sambal Korek']);

        $this->getJson('/api/v1/products?q=AYAM')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $product->id);
    }

    public function test_search_matches_canteen_name_substring(): void
    {
        $canteen = Canteen::factory()->create(['name' => 'Kantin Bu Sari']);
        $product = Product::factory()->for($canteen)->create(['name' => 'Nasi Rendang']);

        $this->getJson('/api/v1/products?q=sari')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $product->id);
    }

    public function test_canteen_and_category_filters_are_intersected(): void
    {
        $canteenA = Canteen::factory()->create();
        $canteenB = Canteen::factory()->create();
        $food = Category::factory()->create(['name' => 'Nasi']);
        $drink = Category::factory()->create(['name' => 'Minuman']);

        $target = Product::factory()->for($canteenA)->create(['category_id' => $food->id]);
        Product::factory()->for($canteenA)->create(['category_id' => $drink->id]);
        Product::factory()->for($canteenB)->create(['category_id' => $food->id]);

        $this->getJson("/api/v1/products?canteen_id={$canteenA->id}&category_id={$food->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $target->id);
    }

    public function test_search_without_match_returns_empty_data(): void
    {
        Product::factory()->create(['name' => 'Nasi Rendang']);

        $this->getJson('/api/v1/products?q=tidakada')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_canteen_detail_only_returns_its_products(): void
    {
        $canteen = Canteen::factory()->create();
        $other = Canteen::factory()->create();
        $own = Product::factory()->for($canteen)->create();
        Product::factory()->for($other)->create();

        $this->getJson("/api/v1/canteens/{$canteen->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data.products')
            ->assertJsonPath('data.products.0.id', $own->id);
    }

    public function test_product_detail_returns_addons(): void
    {
        $product = Product::factory()->create();
        $addon = Addon::factory()->for($product)->create();

        $this->getJson("/api/v1/products/{$product->id}")
            ->assertOk()
            ->assertJsonPath('data.addons.0.id', $addon->id);
    }

    public function test_product_addon_endpoint_only_returns_available_addons(): void
    {
        $product = Product::factory()->create();
        $available = Addon::factory()->for($product)->create();
        Addon::factory()->for($product)->unavailable()->create();

        $this->getJson("/api/v1/products/{$product->id}/addons")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $available->id);
    }

    public function test_categories_endpoint_only_returns_active_categories(): void
    {
        $active = Category::factory()->create();
        Category::factory()->create(['is_active' => false]);

        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $active->id);
    }

    public function test_invalid_filter_returns_validation_error(): void
    {
        $this->getJson('/api/v1/products?canteen_id=bukan-uuid')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['canteen_id']);
    }
}
