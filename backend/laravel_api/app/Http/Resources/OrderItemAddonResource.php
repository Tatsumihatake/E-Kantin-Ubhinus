<?php

namespace App\Http\Resources;

use App\Models\OrderItemAddon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin OrderItemAddon
 */
class OrderItemAddonResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'addon_id' => $this->addon_id,
            'name' => $this->addon_name_snapshot,
            'price' => $this->addon_price,
            'quantity' => $this->quantity,
        ];
    }
}
