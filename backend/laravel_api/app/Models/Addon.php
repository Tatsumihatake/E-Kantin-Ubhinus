<?php

namespace App\Models;

use App\Enums\SelectionRule;
use Database\Factories\AddonFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['product_id', 'name', 'price', 'selection_rule', 'is_available'])]
class Addon extends Model
{
    /** @use HasFactory<AddonFactory> */
    use HasFactory, HasUuids;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'selection_rule' => SelectionRule::class,
            'is_available' => 'boolean',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
