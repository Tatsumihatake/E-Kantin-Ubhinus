<?php

namespace App\Policies;

use App\Enums\Role;
use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    public function view(User $user, Order $order): bool
    {
        if ($user->role === Role::Customer) {
            return $order->customer_id === $user->id;
        }

        if ($user->role === Role::Seller) {
            return $order->canteen()->where('seller_id', $user->id)->exists();
        }

        return false;
    }
}
