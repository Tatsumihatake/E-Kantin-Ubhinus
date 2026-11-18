<?php

namespace App\Http\Resources;

use App\Models\Canteen;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Canteen
 */
class CanteenResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'image_url' => $this->imageUrl(),
            'opening_hours' => $this->opening_hours,
            'is_open' => $this->is_open,
            'products_count' => $this->whenCounted('products'),
            'products' => ProductResource::collection($this->whenLoaded('products')),
        ];
    }

    private function imageUrl(): ?string
    {
        if ($this->image_url === null || $this->image_url === '') {
            return null;
        }

        if (str_starts_with($this->image_url, 'http')) {
            return $this->image_url;
        }

        $path = preg_replace('#^/?storage/#', '', $this->image_url);

        return url('/api/v1/media/'.$path);
    }
}
