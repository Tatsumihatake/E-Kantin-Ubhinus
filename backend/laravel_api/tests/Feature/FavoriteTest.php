<?php

namespace Tests\Feature;

use App\Models\Favorite;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FavoriteTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_add_and_list_favorite(): void
    {
        $customer = User::factory()->customer()->create();
        $product = Product::factory()->create();
        Sanctum::actingAs($customer);

        $this->postJson('/api/v1/favorites', ['product_id' => $product->id])
            ->assertCreated()
            ->assertJsonPath('data.product.id', $product->id);

        $this->getJson('/api/v1/favorites')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_adding_same_favorite_twice_does_not_duplicate(): void
    {
        $customer = User::factory()->customer()->create();
        $product = Product::factory()->create();
        Sanctum::actingAs($customer);

        $this->postJson('/api/v1/favorites', ['product_id' => $product->id])->assertCreated();
        $this->postJson('/api/v1/favorites', ['product_id' => $product->id])->assertOk();

        $this->assertDatabaseCount('favorites', 1);
    }

    public function test_customer_can_remove_favorite(): void
    {
        $customer = User::factory()->customer()->create();
        $product = Product::factory()->create();
        Favorite::factory()->create([
            'customer_id' => $customer->id,
            'product_id' => $product->id,
        ]);
        Sanctum::actingAs($customer);

        $this->deleteJson("/api/v1/favorites/{$product->id}")->assertNoContent();

        $this->assertDatabaseCount('favorites', 0);
    }

    public function test_customer_only_sees_own_favorites(): void
    {
        $customer = User::factory()->customer()->create();
        Favorite::factory()->create();
        Sanctum::actingAs($customer);

        $this->getJson('/api/v1/favorites')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_seller_cannot_access_favorites(): void
    {
        Sanctum::actingAs(User::factory()->seller()->create());

        $this->getJson('/api/v1/favorites')->assertForbidden();
    }

    public function test_guest_cannot_access_favorites(): void
    {
        $this->getJson('/api/v1/favorites')->assertUnauthorized();
    }
}
