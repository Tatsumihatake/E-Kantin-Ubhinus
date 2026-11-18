<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\SelectionRule;
use App\Models\Addon;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderService
{
    /**
     * @param  array{product_id: string, quantity: int, addon_ids?: array<int, string>, request?: ?string}  $data
     * @return array<string, mixed>
     */
    public function preview(array $data): array
    {
        $product = Product::query()
            ->with(['canteen', 'category'])
            ->findOrFail($data['product_id']);

        return $this->calculate($product, $data);
    }

    /**
     * @param  array{product_id: string, quantity: int, addon_ids?: array<int, string>, request?: ?string}  $data
     */
    public function create(User $customer, array $data): Order
    {
        return DB::transaction(function () use ($customer, $data): Order {
            $product = Product::query()
                ->with(['canteen', 'category'])
                ->lockForUpdate()
                ->findOrFail($data['product_id']);

            $selection = $this->calculate($product, $data);

            $order = Order::query()->create([
                'customer_id' => $customer->id,
                'canteen_id' => $product->canteen_id,
                'status' => OrderStatus::WaitingPayment,
                'subtotal' => $selection['total'],
                'total' => $selection['total'],
                'request' => $data['request'] ?? null,
            ]);

            $item = $order->items()->create([
                'product_id' => $product->id,
                'product_name_snapshot' => $product->name,
                'unit_price' => $selection['unit_price'],
                'quantity' => $selection['quantity'],
                'subtotal' => $selection['total'],
            ]);

            foreach ($selection['addons'] as $addon) {
                $item->addons()->create([
                    'addon_id' => $addon->id,
                    'addon_name_snapshot' => $addon->name,
                    'addon_price' => $addon->price,
                    'quantity' => 1,
                ]);
            }

            $order->statusHistory()->create([
                'old_status' => null,
                'new_status' => OrderStatus::WaitingPayment,
                'changed_by' => $customer->id,
                'note' => 'Order dibuat.',
            ]);

            return $order->load(['items.addons', 'canteen', 'statusHistory']);
        });
    }

    public function transition(Order $order, OrderStatus $next, ?User $actor, ?string $note = null): Order
    {
        return DB::transaction(function () use ($order, $next, $actor, $note): Order {
            $locked = Order::query()->lockForUpdate()->findOrFail($order->id);

            if (! $locked->status->canTransitionTo($next)) {
                throw ValidationException::withMessages([
                    'status' => "Transisi dari {$locked->status->label()} ke {$next->label()} tidak diizinkan.",
                ]);
            }

            $oldStatus = $locked->status;

            $locked->update(['status' => $next]);

            $locked->statusHistory()->create([
                'old_status' => $oldStatus,
                'new_status' => $next,
                'changed_by' => $actor?->id,
                'note' => $note,
            ]);

            return $locked->load(['items.addons', 'canteen', 'statusHistory']);
        });
    }

    /**
     * @param  array{quantity: int, addon_ids?: array<int, string>, request?: ?string}  $data
     * @return array<string, mixed>
     */
    private function calculate(Product $product, array $data): array
    {
        if (! $product->is_available) {
            throw ValidationException::withMessages([
                'product_id' => 'Menu sedang tidak tersedia.',
            ]);
        }

        if (! $product->canteen->is_open) {
            throw ValidationException::withMessages([
                'product_id' => 'Kantin sedang tutup.',
            ]);
        }

        $quantity = (int) $data['quantity'];
        $addonIds = array_values(array_unique($data['addon_ids'] ?? []));

        /** @var Collection<int, Addon> $addons */
        $addons = Addon::query()
            ->where('product_id', $product->id)
            ->whereIn('id', $addonIds)
            ->get();

        if ($addons->count() !== count($addonIds)) {
            throw ValidationException::withMessages([
                'addon_ids' => 'Add-on tidak valid untuk menu ini.',
            ]);
        }

        if ($addons->contains(fn (Addon $addon): bool => ! $addon->is_available)) {
            throw ValidationException::withMessages([
                'addon_ids' => 'Salah satu add-on sedang tidak tersedia.',
            ]);
        }

        $requiredAddonIds = $product->addons()
            ->where('selection_rule', SelectionRule::Required)
            ->where('is_available', true)
            ->pluck('id')
            ->all();

        if (array_diff($requiredAddonIds, $addonIds) !== []) {
            throw ValidationException::withMessages([
                'addon_ids' => 'Add-on wajib belum dipilih.',
            ]);
        }

        $unitPrice = (float) $product->price;
        $addonTotal = (float) $addons->sum(fn (Addon $addon): float => (float) $addon->price);
        $unitTotal = $unitPrice + $addonTotal;
        $total = $unitTotal * $quantity;

        return [
            'product' => $product,
            'quantity' => $quantity,
            'addons' => $addons,
            'request' => $data['request'] ?? null,
            'unit_price' => number_format($unitPrice, 2, '.', ''),
            'addons_total' => number_format($addonTotal, 2, '.', ''),
            'unit_total' => number_format($unitTotal, 2, '.', ''),
            'total' => number_format($total, 2, '.', ''),
        ];
    }
}
