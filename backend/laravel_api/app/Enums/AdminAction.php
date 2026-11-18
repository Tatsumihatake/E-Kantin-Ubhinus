<?php

namespace App\Enums;

enum AdminAction: string
{
    case CreateAccount = 'CREATE_ACCOUNT';
    case UpdateAccount = 'UPDATE_ACCOUNT';
    case ActivateAccount = 'ACTIVATE_ACCOUNT';
    case DeactivateAccount = 'DEACTIVATE_ACCOUNT';

    public function label(): string
    {
        return match ($this) {
            self::CreateAccount => 'Membuat Akun',
            self::UpdateAccount => 'Mengubah Akun',
            self::ActivateAccount => 'Mengaktifkan Akun',
            self::DeactivateAccount => 'Menonaktifkan Akun',
        };
    }
}
