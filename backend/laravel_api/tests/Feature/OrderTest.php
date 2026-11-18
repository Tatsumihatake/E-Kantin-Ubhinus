<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Models\Addon;
use App\Models\Canteen;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    private function productWithAddons(int $price = 18000): array
    {
        $canteen = Canteen::factory()->create(['is_open' => true]);
        $product = Product::factory()->for($canteen)->create(['price' => $price, 'is_available' => true]);
        $optional = Addon::factory()->for($product)->create(['price' => 3000]);
        $required = Addon::factory()->for($product)->required()->create(['price' => 0]);

        return [$product, $optional, $required];
    }

    public function test_preview_calculates_total_from_server_prices(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson('/api/v1/orders/preview', [
            'product_id' => $product->id,
            'quantity' => 2,
            'addon_ids' => [$optional->id, $required->id],
            'request' => 'Jangan pedas',
        ])
            ->assertOk()
            ->assertJsonPath('data.total', '42000.00')
            ->assertJsonPath('data.quantity', 2)
            ->assertJsonPath('data.request', 'Jangan pedas');
    }

    public function test_preview_rejects_unavailable_product(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        $product->update(['is_available' => false]);
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson('/api/v1/orders/preview', [
            'product_id' => $product->id,
            'quantity' => 1,
            'addon_ids' => [$optional->id, $required->id],
        ])->assertUnprocessable()->assertJsonValidationErrors(['product_id']);
    }

    public function test_preview_rejects_closed_canteen(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        $product->canteen->update(['is_open' => false]);
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson('/api/v1/orders/preview', [
            'product_id' => $product->id,
            'quantity' => 1,
            'addon_ids' => [$optional->id, $required->id],
        ])->assertUnprocessable()->assertJsonValidationErrors(['product_id']);
    }

    public function test_preview_requires_required_addons(): void
    {
        [$product, $optional] = $this->productWithAddons();
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson('/api/v1/orders/preview', [
            'product_id' => $product->id,
            'quantity' => 1,
            'addon_ids' => [$optional->id],
        ])->assertUnprocessable()->assertJsonValidationErrors(['addon_ids']);
    }

    public function test_customer_can_create_order_with_snapshot_and_history(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        $customer = User::factory()->customer()->create();
        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/v1/orders', [
            'product_id' => $product->id,
            'quantity' => 2,
            'addon_ids' => [$optional->id, $required->id],
            'request' => 'Sambal dipisah',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.status', 'WAITING_PAYMENT')
            ->assertJsonPath('data.total', '42000.00')
            ->assertJsonPath('data.items.0.name', $product->name)
            ->assertJsonPath('data.items.0.addons.0.name', $optional->name);

        $this->assertDatabaseHas('order_items', [
            'product_id' => $product->id,
            'product_name_snapshot' => $product->name,
            'unit_price' => 18000,
            'quantity' => 2,
        ]);
        $this->assertDatabaseHas('order_status_history', [
            'new_status' => 'WAITING_PAYMENT',
        ]);
    }

    public function test_idempotency_key_prevents_duplicate_order(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        Sanctum::actingAs(User::factory()->customer()->create());

        $payload = [
            'product_id' => $product->id,
            'quantity' => 1,
            'addon_ids' => [$optional->id, $required->id],
            'idempotency_key' => 'klik-sekali',
        ];

        $this->postJson('/api/v1/orders', $payload)->assertCreated();
        $this->postJson('/api/v1/orders', $payload)->assertOk();

        $this->assertDatabaseCount('orders', 1);
    }

    public function test_customer_only_lists_own_orders_and_can_filter_tab(): void
    {
        $customer = User::factory()->customer()->create();
        Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::WaitingPayment]);
        Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::Completed]);
        Order::factory()->create();
        Sanctum::actingAs($customer);

        $this->getJson('/api/v1/orders')->assertOk()->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/orders?tab=active')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/orders?tab=finished')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_order_detail_is_limited_to_owner_and_canteen_seller(): void
    {
        $seller = User::factory()->seller()->create();
        $canteen = Canteen::factory()->for($seller, 'seller')->create();
        $order = Order::factory()->for($canteen)->create();
        $owner = User::query()->find($order->customer_id);

        Sanctum::actingAs($owner);
        $this->getJson("/api/v1/orders/{$order->id}")->assertOk();

        Sanctum::actingAs($seller);
        $this->getJson("/api/v1/orders/{$order->id}")->assertOk();

        Sanctum::actingAs(User::factory()->customer()->create());
        $this->getJson("/api/v1/orders/{$order->id}")->assertForbidden();

        Sanctum::actingAs(User::factory()->seller()->create());
        $this->getJson("/api/v1/orders/{$order->id}")->assertForbidden();
    }

    public function test_status_history_endpoint_returns_timeline(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create();
        $order->statusHistory()->create([
            'old_status' => null,
            'new_status' => OrderStatus::WaitingPayment,
            'changed_by' => $customer->id,
        ]);
        Sanctum::actingAs($customer);

        $this->getJson("/api/v1/orders/{$order->id}/status-history")
            ->assertOk()
            ->assertJsonPath('data.0.new_status', 'WAITING_PAYMENT');
    }

    public function test_quantity_below_one_is_rejected(): void
    {
        [$product, $optional, $required] = $this->productWithAddons();
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson('/api/v1/orders/preview', [
            'product_id' => $product->id,
            'quantity' => 0,
            'addon_ids' => [$optional->id, $required->id],
        ])->assertUnprocessable()->assertJsonValidationErrors(['quantity']);
    }
}
