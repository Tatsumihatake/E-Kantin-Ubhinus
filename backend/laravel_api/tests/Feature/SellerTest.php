<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Models\Addon;
use App\Models\Canteen;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SellerTest extends TestCase
{
    use RefreshDatabase;

    private function sellerWithCanteen(): array
    {
        $seller = User::factory()->seller()->create();
        $canteen = Canteen::factory()->for($seller, 'seller')->create();

        return [$seller, $canteen];
    }

    public function test_seller_sees_own_canteen(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        Sanctum::actingAs($seller);

        $this->getJson('/api/v1/seller/canteen')
            ->assertOk()
            ->assertJsonPath('data.id', $canteen->id);
    }

    public function test_seller_can_toggle_canteen_open_status(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        Sanctum::actingAs($seller);

        $this->patchJson('/api/v1/seller/canteen', ['is_open' => false])
            ->assertOk()
            ->assertJsonPath('data.is_open', false);

        $this->assertDatabaseHas('canteens', ['id' => $canteen->id, 'is_open' => false]);
    }

    public function test_seller_creates_product_under_own_canteen(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $category = Category::factory()->create();
        Sanctum::actingAs($seller);

        $response = $this->postJson('/api/v1/seller/products', [
            'name' => 'Nasi Goreng',
            'price' => 15000,
            'category_id' => $category->id,
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.name', 'Nasi Goreng')
            ->assertJsonPath('data.canteen_id', $canteen->id);

        $this->assertDatabaseHas('products', ['name' => 'Nasi Goreng', 'canteen_id' => $canteen->id]);
    }

    public function test_product_validation_rejects_empty_name_and_negative_price(): void
    {
        [$seller] = $this->sellerWithCanteen();
        Sanctum::actingAs($seller);

        $this->postJson('/api/v1/seller/products', ['name' => '', 'price' => -1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'price']);
    }

    public function test_seller_cannot_access_other_seller_product(): void
    {
        [$seller] = $this->sellerWithCanteen();
        $foreignProduct = Product::factory()->create();
        Sanctum::actingAs($seller);

        $this->getJson("/api/v1/seller/products/{$foreignProduct->id}")->assertForbidden();
        $this->patchJson("/api/v1/seller/products/{$foreignProduct->id}", ['name' => 'X'])->assertForbidden();
        $this->deleteJson("/api/v1/seller/products/{$foreignProduct->id}")->assertForbidden();
    }

    public function test_seller_can_create_and_update_product_with_image_upload(): void
    {
        Storage::fake('public');
        [$seller, $canteen] = $this->sellerWithCanteen();
        Sanctum::actingAs($seller);

        $productId = $this->post('/api/v1/seller/products', [
            'name' => 'Menu Foto',
            'price' => 15000,
            'image' => UploadedFile::fake()->image('menu.jpg'),
        ])->assertCreated()->json('data.id');

        $product = Product::query()->findOrFail($productId);
        $this->assertStringContainsString('/storage/products/', $product->image_url);

        $this->post("/api/v1/seller/products/{$productId}", [
            '_method' => 'PATCH',
            'name' => 'Menu Foto Baru',
            'image' => UploadedFile::fake()->image('menu-baru.jpg'),
        ])->assertOk()->assertJsonPath('data.name', 'Menu Foto Baru');

        $this->assertDatabaseHas('products', ['id' => $productId, 'name' => 'Menu Foto Baru']);
    }

    public function test_seller_can_update_product(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $product = Product::factory()->for($canteen)->create(['price' => 10000]);
        Sanctum::actingAs($seller);

        $this->patchJson("/api/v1/seller/products/{$product->id}", [
            'price' => 12500,
            'is_available' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.price', '12500.00')
            ->assertJsonPath('data.is_available', false);
    }

    public function test_delete_product_deactivates_instead_of_removing_history(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $product = Product::factory()->for($canteen)->create(['is_available' => true]);
        Sanctum::actingAs($seller);

        $this->deleteJson("/api/v1/seller/products/{$product->id}")->assertNoContent();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'is_available' => false]);
    }

    public function test_seller_manages_addons_of_own_product_only(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $product = Product::factory()->for($canteen)->create();
        $foreignAddon = Addon::factory()->create();
        Sanctum::actingAs($seller);

        $addonId = $this->postJson("/api/v1/seller/products/{$product->id}/addons", [
            'name' => 'Telur',
            'price' => 3000,
            'selection_rule' => 'REQUIRED',
        ])->assertCreated()->json('data.id');

        $this->patchJson("/api/v1/seller/addons/{$addonId}", ['price' => 3500])
            ->assertOk()
            ->assertJsonPath('data.price', '3500.00');

        $this->deleteJson("/api/v1/seller/addons/{$addonId}")->assertNoContent();

        $this->patchJson("/api/v1/seller/addons/{$foreignAddon->id}", ['price' => 1000])->assertForbidden();
        $this->deleteJson("/api/v1/seller/addons/{$foreignAddon->id}")->assertForbidden();
    }

    public function test_seller_only_lists_orders_for_own_canteen(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $ownOrder = Order::factory()->for($canteen)->create();
        Order::factory()->create();
        Sanctum::actingAs($seller);

        $this->getJson('/api/v1/seller/orders')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ownOrder->id);
    }

    public function test_seller_accepts_paid_order(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $order = Order::factory()->for($canteen)->create(['status' => OrderStatus::Paid]);
        Sanctum::actingAs($seller);

        $this->postJson("/api/v1/seller/orders/{$order->id}/accept")
            ->assertOk()
            ->assertJsonPath('data.status', 'CONFIRMED');
    }

    public function test_seller_rejects_paid_order_with_reason(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $order = Order::factory()->for($canteen)->create(['status' => OrderStatus::Paid]);
        Sanctum::actingAs($seller);

        $this->postJson("/api/v1/seller/orders/{$order->id}/reject", ['reason' => 'Bahan habis'])
            ->assertOk()
            ->assertJsonPath('data.status', 'REJECTED')
            ->assertJsonPath('data.rejection_reason', 'Bahan habis');
    }

    public function test_illegal_status_transition_is_rejected(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $order = Order::factory()->for($canteen)->create(['status' => OrderStatus::WaitingPayment]);
        Sanctum::actingAs($seller);

        $this->postJson("/api/v1/seller/orders/{$order->id}/accept")
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status']);
    }

    public function test_seller_cannot_process_other_canteen_order(): void
    {
        [$seller] = $this->sellerWithCanteen();
        $foreignOrder = Order::factory()->create(['status' => OrderStatus::Paid]);
        Sanctum::actingAs($seller);

        $this->postJson("/api/v1/seller/orders/{$foreignOrder->id}/accept")->assertForbidden();
    }

    public function test_customer_cannot_access_seller_area(): void
    {
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->getJson('/api/v1/seller/products')->assertForbidden();
    }

    public function test_seller_updates_order_status_step_by_step(): void
    {
        [$seller, $canteen] = $this->sellerWithCanteen();
        $order = Order::factory()->for($canteen)->create(['status' => OrderStatus::Confirmed]);
        Sanctum::actingAs($seller);

        $this->patchJson("/api/v1/seller/orders/{$order->id}/status", ['status' => 'PREPARING'])
            ->assertOk()->assertJsonPath('data.status', 'PREPARING');
        $this->patchJson("/api/v1/seller/orders/{$order->id}/status", ['status' => 'READY'])
            ->assertOk()->assertJsonPath('data.status', 'READY');
        $this->patchJson("/api/v1/seller/orders/{$order->id}/status", ['status' => 'COMPLETED'])
            ->assertOk()->assertJsonPath('data.status', 'COMPLETED');

        $this->assertDatabaseCount('order_status_history', 3);
    }
}
