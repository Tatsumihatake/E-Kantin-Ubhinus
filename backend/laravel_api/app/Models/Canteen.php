<?php

namespace App\Models;

use Database\Factories\CanteenFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['seller_id', 'name', 'description', 'image_url', 'opening_hours', 'is_open'])]
class Canteen extends Model
{
    /** @use HasFactory<CanteenFactory> */
    use HasFactory, HasUuids;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'opening_hours' => 'array',
            'is_open' => 'boolean',
        ];
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
