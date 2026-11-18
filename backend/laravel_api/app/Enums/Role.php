<?php

namespace App\Enums;

enum Role: string
{
    case Customer = 'CUSTOMER';
    case Seller = 'SELLER';
    case Admin = 'ADMIN';

    public function label(): string
    {
        return match ($this) {
            self::Customer => 'Customer',
            self::Seller => 'Seller',
            self::Admin => 'Admin',
        };
    }
}
