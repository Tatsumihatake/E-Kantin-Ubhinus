<?php

namespace App\Http\Resources;

use App\Models\Addon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Addon
 */
class AddonResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_id' => $this->product_id,
            'name' => $this->name,
            'price' => $this->price,
            'selection_rule' => $this->selection_rule->value,
            'selection_rule_label' => $this->selection_rule->label(),
            'is_available' => $this->is_available,
        ];
    }
}
