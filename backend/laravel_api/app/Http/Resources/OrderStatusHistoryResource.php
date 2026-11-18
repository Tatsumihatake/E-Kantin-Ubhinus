<?php

namespace App\Http\Resources;

use App\Models\OrderStatusHistory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin OrderStatusHistory
 */
class OrderStatusHistoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'old_status' => $this->old_status?->value,
            'new_status' => $this->new_status->value,
            'new_status_label' => $this->new_status->label(),
            'note' => $this->note,
            'changed_by' => $this->whenLoaded('changedBy', fn () => [
                'id' => $this->changedBy?->id,
                'name' => $this->changedBy?->name,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
