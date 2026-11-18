<?php

namespace Tests\Feature;

use App\Models\Canteen;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminSellerTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->admin()->create();
    }

    public function test_admin_creates_seller_with_canteen_and_can_login(): void
    {
        Sanctum::actingAs($this->admin());

        $response = $this->postJson('/api/v1/admin/sellers', [
            'name' => 'Bu Ratna',
            'email' => 'ratna@example.test',
            'password' => 'password123',
            'phone' => '081200001111',
            'canteen_name' => 'Kantin Bu Ratna',
            'canteen_description' => 'Masakan Jawa',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.role', 'SELLER')
            ->assertJsonPath('data.canteens.0.name', 'Kantin Bu Ratna');

        $seller = User::query()->where('email', 'ratna@example.test')->firstOrFail();
        $this->assertDatabaseHas('canteens', ['seller_id' => $seller->id, 'name' => 'Kantin Bu Ratna']);
        $this->assertDatabaseHas('admin_activity_logs', ['seller_id' => $seller->id, 'action' => 'CREATE_ACCOUNT']);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'ratna@example.test',
            'password' => 'password123',
        ])->assertOk()->assertJsonPath('data.user.role', 'SELLER');
    }

    public function test_admin_cannot_create_duplicate_email(): void
    {
        User::factory()->create(['email' => 'dipakai@example.test']);
        Sanctum::actingAs($this->admin());

        $this->postJson('/api/v1/admin/sellers', [
            'name' => 'Duplikat',
            'email' => 'dipakai@example.test',
            'password' => 'password123',
            'canteen_name' => 'Kantin Duplikat',
        ])->assertUnprocessable()->assertJsonValidationErrors(['email']);
    }

    public function test_seller_creation_validates_required_fields(): void
    {
        Sanctum::actingAs($this->admin());

        $this->postJson('/api/v1/admin/sellers', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password', 'canteen_name']);
    }

    public function test_non_admin_cannot_manage_sellers(): void
    {
        Sanctum::actingAs(User::factory()->seller()->create());

        $this->getJson('/api/v1/admin/sellers')->assertForbidden();
        $this->postJson('/api/v1/admin/sellers', [])->assertForbidden();
    }

    public function test_admin_lists_and_filters_sellers(): void
    {
        $active = User::factory()->seller()->create(['name' => 'Sari Aktif']);
        Canteen::factory()->for($active, 'seller')->create(['name' => 'Kantin Sari']);
        $inactive = User::factory()->seller()->inactive()->create(['name' => 'Bambang Nonaktif']);
        Canteen::factory()->for($inactive, 'seller')->create(['name' => 'Geprek Bambang']);
        User::factory()->customer()->create();
        User::factory()->admin()->create();
        Sanctum::actingAs($this->admin());

        $this->getJson('/api/v1/admin/sellers')
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->getJson('/api/v1/admin/sellers?status=inactive')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $inactive->id);

        $this->getJson('/api/v1/admin/sellers?q=bambang')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $inactive->id);
    }

    public function test_admin_can_view_seller_detail_but_not_customer(): void
    {
        $seller = User::factory()->seller()->create();
        Canteen::factory()->for($seller, 'seller')->create();
        $customer = User::factory()->customer()->create();
        Sanctum::actingAs($this->admin());

        $this->getJson("/api/v1/admin/sellers/{$seller->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $seller->id);

        $this->getJson("/api/v1/admin/sellers/{$customer->id}")->assertNotFound();
    }

    public function test_admin_updates_seller_and_canteen(): void
    {
        $seller = User::factory()->seller()->create(['email' => 'lama@example.test']);
        Canteen::factory()->for($seller, 'seller')->create(['name' => 'Nama Lama']);
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/v1/admin/sellers/{$seller->id}", [
            'name' => 'Nama Baru',
            'email' => 'baru@example.test',
            'canteen_name' => 'Nama Kantin Baru',
            'is_open' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Nama Baru')
            ->assertJsonPath('data.canteens.0.name', 'Nama Kantin Baru');

        $this->assertDatabaseHas('admin_activity_logs', ['seller_id' => $seller->id, 'action' => 'UPDATE_ACCOUNT']);
    }

    public function test_admin_update_rejects_email_used_by_another_user(): void
    {
        User::factory()->create(['email' => 'milik-orang-lain@example.test']);
        $seller = User::factory()->seller()->create();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/v1/admin/sellers/{$seller->id}", [
            'email' => 'milik-orang-lain@example.test',
        ])->assertUnprocessable()->assertJsonValidationErrors(['email']);
    }

    public function test_activation_deactivates_seller_and_revokes_token(): void
    {
        $seller = User::factory()->seller()->create();
        $token = $seller->createToken('test')->plainTextToken;
        $adminToken = $this->admin()->createToken('admin')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$adminToken)
            ->patchJson("/api/v1/admin/sellers/{$seller->id}/activation", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertSame(0, $seller->tokens()->count());
        $this->assertDatabaseHas('admin_activity_logs', [
            'seller_id' => $seller->id,
            'action' => 'DEACTIVATE_ACCOUNT',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/seller/canteen')
            ->assertForbidden();
    }

    public function test_activation_requires_boolean_value(): void
    {
        $seller = User::factory()->seller()->create();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/v1/admin/sellers/{$seller->id}/activation", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['is_active']);
    }
}
