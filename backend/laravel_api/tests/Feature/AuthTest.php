<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_login_with_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'customer@example.test',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'customer@example.test',
            'password' => 'password',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.user.email', $user->email)
            ->assertJsonPath('data.user.role', 'CUSTOMER')
            ->assertJsonStructure(['data' => ['user', 'token']]);
    }

    public function test_login_rejected_with_wrong_password(): void
    {
        User::factory()->create([
            'email' => 'customer@example.test',
            'password' => 'password',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'customer@example.test',
            'password' => 'salah',
        ])->assertUnauthorized();
    }

    public function test_login_rejected_for_inactive_account(): void
    {
        User::factory()->inactive()->create([
            'email' => 'off@example.test',
            'password' => 'password',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'off@example.test',
            'password' => 'password',
        ])->assertForbidden();
    }

    public function test_login_validates_required_fields(): void
    {
        $this->postJson('/api/v1/auth/login', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_customer_can_register_and_receives_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Siti Rahma',
            'email' => 'siti@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.email', 'siti@example.test')
            ->assertJsonPath('data.user.role', 'CUSTOMER')
            ->assertJsonPath('data.user.is_active', true)
            ->assertJsonStructure(['data' => ['user', 'token']]);

        $this->assertDatabaseHas('users', [
            'email' => 'siti@example.test',
            'role' => 'CUSTOMER',
            'is_active' => true,
        ]);
    }

    public function test_register_ignores_role_from_payload(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'name' => 'Penyusup',
            'email' => 'penyusup@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'ADMIN',
            'is_active' => false,
        ])->assertCreated();

        $this->assertDatabaseHas('users', [
            'email' => 'penyusup@example.test',
            'role' => 'CUSTOMER',
            'is_active' => true,
        ]);
    }

    public function test_register_rejects_duplicate_email(): void
    {
        User::factory()->create(['email' => 'dipakai@example.test']);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Duplikat',
            'email' => 'dipakai@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_register_validates_required_fields_and_password_confirmation(): void
    {
        $this->postJson('/api/v1/auth/register', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password']);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Salah Konfirmasi',
            'email' => 'salah@example.test',
            'password' => 'password123',
            'password_confirmation' => 'beda12345',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['password']);
    }

    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->seller()->create();

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.role', 'SELLER');
    }

    public function test_customer_can_update_own_profile(): void
    {
        $user = User::factory()->customer()->create(['name' => 'Nama Lama', 'phone' => null]);
        Sanctum::actingAs($user);

        $this->patchJson('/api/v1/auth/profile', [
            'name' => 'Nama Baru',
            'phone' => '081299998888',
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Nama Baru')
            ->assertJsonPath('data.phone', '081299998888');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Nama Baru',
            'phone' => '081299998888',
        ]);
    }

    public function test_seller_can_update_own_profile(): void
    {
        $seller = User::factory()->seller()->create();
        Sanctum::actingAs($seller);

        $this->patchJson('/api/v1/auth/profile', ['name' => 'Seller Baru'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Seller Baru')
            ->assertJsonPath('data.role', 'SELLER');
    }

    public function test_profile_update_cannot_change_role_or_active_status(): void
    {
        $user = User::factory()->customer()->create();
        Sanctum::actingAs($user);

        $this->patchJson('/api/v1/auth/profile', [
            'name' => 'Tetap Customer',
            'role' => 'ADMIN',
            'is_active' => false,
        ])->assertOk();

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'role' => 'CUSTOMER',
            'is_active' => true,
        ]);
    }

    public function test_profile_update_validates_name_and_phone(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->patchJson('/api/v1/auth/profile', [
            'name' => '',
            'phone' => str_repeat('1', 21),
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'phone']);
    }

    public function test_profile_update_requires_authentication(): void
    {
        $this->patchJson('/api/v1/auth/profile', ['name' => 'Tanpa Login'])->assertUnauthorized();
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_profile_requires_authentication(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }
}
