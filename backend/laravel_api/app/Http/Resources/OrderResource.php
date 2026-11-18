<?php

namespace App\Http\Resources;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Order
 */
class OrderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'is_active' => $this->status->isActive(),
            'subtotal' => $this->subtotal,
            'total' => $this->total,
            'request' => $this->request,
            'rejection_reason' => $this->rejection_reason,
            'canteen' => new CanteenResource($this->whenLoaded('canteen')),
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'status_history' => OrderStatusHistoryResource::collection($this->whenLoaded('statusHistory')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
