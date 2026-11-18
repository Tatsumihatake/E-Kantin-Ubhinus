<?php

namespace App\Enums;

enum SelectionRule: string
{
    case Optional = 'OPTIONAL';
    case Required = 'REQUIRED';

    public function label(): string
    {
        return match ($this) {
            self::Optional => 'Opsional',
            self::Required => 'Wajib',
        };
    }
}
