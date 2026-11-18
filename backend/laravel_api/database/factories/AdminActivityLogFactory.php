<?php

namespace Database\Factories;

use App\Enums\AdminAction;
use App\Models\AdminActivityLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AdminActivityLog>
 */
class AdminActivityLogFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'admin_id' => User::factory()->admin(),
            'seller_id' => User::factory()->seller(),
            'action' => AdminAction::CreateAccount,
            'description' => fake()->sentence(),
        ];
    }
}
