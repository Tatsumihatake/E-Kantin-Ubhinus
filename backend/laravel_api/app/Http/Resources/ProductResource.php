<?php

namespace App\Http\Resources;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Product
 */
class ProductResource extends JsonResource
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
            'price' => $this->price,
            'is_available' => $this->is_available,
            'canteen_id' => $this->canteen_id,
            'category_id' => $this->category_id,
            'canteen' => new CanteenResource($this->whenLoaded('canteen')),
            'category' => new CategoryResource($this->whenLoaded('category')),
            'addons' => AddonResource::collection($this->whenLoaded('addons')),
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
