<?php

namespace App\Models;

use App\Enums\AdminAction;
use Database\Factories\AdminActivityLogFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['admin_id', 'seller_id', 'action', 'description'])]
class AdminActivityLog extends Model
{
    /** @use HasFactory<AdminActivityLogFactory> */
    use HasFactory, HasUuids;

    public const UPDATED_AT = null;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'action' => AdminAction::class,
        ];
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }
}
