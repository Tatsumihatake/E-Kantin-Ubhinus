<?php

namespace Tests\Feature;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_start_qris_mock_payment(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create([
            'status' => OrderStatus::WaitingPayment,
            'total' => 25000,
        ]);
        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/orders/{$order->id}/payments")
            ->assertCreated()
            ->assertJsonPath('data.method', 'QRIS')
            ->assertJsonPath('data.status', 'PENDING')
            ->assertJsonPath('data.amount', '25000.00')
            ->assertJsonPath('data.is_simulation', true)
            ->assertJsonStructure(['data' => ['qris_payload', 'reference']]);
    }

    public function test_non_owner_cannot_start_payment(): void
    {
        $order = Order::factory()->create(['status' => OrderStatus::WaitingPayment]);
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->postJson("/api/v1/orders/{$order->id}/payments")->assertForbidden();
    }

    public function test_successful_simulation_marks_order_paid(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::WaitingPayment]);
        Sanctum::actingAs($customer);

        $paymentId = $this->postJson("/api/v1/orders/{$order->id}/payments")
            ->assertCreated()
            ->json('data.id');

        $this->postJson("/api/v1/payments/{$paymentId}/simulate-result", ['result' => 'success'])
            ->assertOk()
            ->assertJsonPath('data.status', 'SUCCESS');

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'PAID']);
        $this->assertDatabaseHas('order_status_history', ['order_id' => $order->id, 'new_status' => 'PAID']);
    }

    public function test_failed_simulation_keeps_order_waiting_payment(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::WaitingPayment]);
        Sanctum::actingAs($customer);

        $paymentId = $this->postJson("/api/v1/orders/{$order->id}/payments")->json('data.id');

        $this->postJson("/api/v1/payments/{$paymentId}/simulate-result", ['result' => 'failed'])
            ->assertOk()
            ->assertJsonPath('data.status', 'FAILED');

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'WAITING_PAYMENT']);
    }

    public function test_finished_payment_cannot_be_simulated_again(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::WaitingPayment]);
        $payment = Payment::factory()->for($order)->success()->create();
        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/payments/{$payment->id}/simulate-result", ['result' => 'success'])
            ->assertStatus(409);
    }

    public function test_cannot_start_payment_after_order_paid(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::Paid]);
        Payment::factory()->for($order)->success()->create();
        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/orders/{$order->id}/payments")->assertStatus(409);
    }

    public function test_stale_pending_attempt_cannot_be_paid_after_order_paid(): void
    {
        $customer = User::factory()->customer()->create();
        $order = Order::factory()->for($customer, 'customer')->create(['status' => OrderStatus::WaitingPayment]);
        $first = Payment::factory()->for($order)->create();
        $second = Payment::factory()->for($order)->create();
        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/payments/{$first->id}/simulate-result", ['result' => 'success'])->assertOk();

        $this->postJson("/api/v1/payments/{$second->id}/simulate-result", ['result' => 'success'])
            ->assertStatus(409);

        $this->assertDatabaseHas('payments', ['id' => $second->id, 'status' => 'PENDING']);
    }

    public function test_non_owner_cannot_view_payment(): void
    {
        $payment = Payment::factory()->create();
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->getJson("/api/v1/payments/{$payment->id}")->assertForbidden();
    }

    public function test_simulation_requires_result_value(): void
    {
        $customer = User::factory()->customer()->create();
        $payment = Payment::factory()->for(
            Order::factory()->for($customer, 'customer')
        )->create();
        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/payments/{$payment->id}/simulate-result", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['result']);
    }

    public function test_payment_status_enum_values_are_consistent(): void
    {
        $this->assertSame('PENDING', PaymentStatus::Pending->value);
        $this->assertSame('SUCCESS', PaymentStatus::Success->value);
        $this->assertSame('FAILED', PaymentStatus::Failed->value);
    }
}
