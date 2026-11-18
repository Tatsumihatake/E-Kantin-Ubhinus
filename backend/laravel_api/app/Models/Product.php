<?php

namespace App\Models;

use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['canteen_id', 'category_id', 'name', 'description', 'image_url', 'price', 'is_available'])]
class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory, HasUuids;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'is_available' => 'boolean',
        ];
    }

    public function canteen(): BelongsTo
    {
        return $this->belongsTo(Canteen::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function addons(): HasMany
    {
        return $this->hasMany(Addon::class);
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }
}
