<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Database\Factories\OrderStatusHistoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['order_id', 'old_status', 'new_status', 'changed_by', 'note'])]
class OrderStatusHistory extends Model
{
    /** @use HasFactory<OrderStatusHistoryFactory> */
    use HasFactory, HasUuids;

    public const UPDATED_AT = null;

    protected $table = 'order_status_history';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'old_status' => OrderStatus::class,
            'new_status' => OrderStatus::class,
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
