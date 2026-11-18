<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['auth:sanctum', 'role:ADMIN'])
            ->get('/api/v1/__test/admin-only', fn () => response()->json(['ok' => true]));
    }

    public function test_customer_is_forbidden_from_admin_route(): void
    {
        Sanctum::actingAs(User::factory()->customer()->create());

        $this->getJson('/api/v1/__test/admin-only')->assertForbidden();
    }

    public function test_admin_can_access_admin_route(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->getJson('/api/v1/__test/admin-only')
            ->assertOk()
            ->assertJsonPath('ok', true);
    }

    public function test_inactive_admin_is_forbidden(): void
    {
        Sanctum::actingAs(User::factory()->admin()->inactive()->create());

        $this->getJson('/api/v1/__test/admin-only')->assertForbidden();
    }

    public function test_guest_is_unauthenticated(): void
    {
        $this->getJson('/api/v1/__test/admin-only')->assertUnauthorized();
    }
}
