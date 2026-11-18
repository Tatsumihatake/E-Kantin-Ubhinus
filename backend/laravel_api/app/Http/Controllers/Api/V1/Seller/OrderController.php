<?php

namespace App\Http\Controllers\Api\V1\Seller;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Seller\RejectOrderRequest;
use App\Http\Requests\Api\V1\Seller\UpdateOrderStatusRequest;
use App\Http\Resources\OrderResource;
use App\Models\Canteen;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class OrderController extends Controller
{
    public function __construct(private readonly OrderService $orderService) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $canteen = $this->canteen($request->user());
        $validated = $request->validate([
            'tab' => ['nullable', 'in:active,history'],
        ]);

        $tab = $validated['tab'] ?? null;

        $statuses = collect(OrderStatus::cases())
            ->filter(fn (OrderStatus $status): bool => match ($tab) {
                'active' => $status->isActive(),
                'history' => $status->isFinal(),
                default => true,
            })
            ->map(fn (OrderStatus $status): string => $status->value)
            ->all();

        $orders = Order::query()
            ->where('canteen_id', $canteen->id)
            ->whereIn('status', $statuses)
            ->with(['items.addons', 'canteen'])
            ->latest('created_at')
            ->paginate(20);

        return OrderResource::collection($orders);
    }

    public function history(Request $request): AnonymousResourceCollection
    {
        $request->merge(['tab' => 'history']);

        return $this->index($request);
    }

    public function accept(Request $request, Order $order): OrderResource
    {
        $this->authorizeOrder($request->user(), $order);

        $order = $this->orderService->transition($order, OrderStatus::Confirmed, $request->user(), 'Pesanan diterima Seller.');

        return new OrderResource($order);
    }

    public function reject(RejectOrderRequest $request, Order $order): OrderResource
    {
        $this->authorizeOrder($request->user(), $order);

        $order = $this->orderService->transition(
            $order,
            OrderStatus::Rejected,
            $request->user(),
            $request->validated('reason') ?? 'Pesanan ditolak Seller.'
        );

        $order->update(['rejection_reason' => $request->validated('reason')]);

        return new OrderResource($order);
    }

    public function updateStatus(UpdateOrderStatusRequest $request, Order $order): OrderResource
    {
        $this->authorizeOrder($request->user(), $order);

        $next = OrderStatus::from($request->validated('status'));

        $order = $this->orderService->transition($order, $next, $request->user(), $request->validated('note'));

        return new OrderResource($order);
    }

    private function canteen(User $seller): Canteen
    {
        $canteen = $seller->canteens()->first();

        abort_if($canteen === null, 403, 'Akun Seller belum terhubung dengan kantin.');

        return $canteen;
    }

    private function authorizeOrder(User $seller, Order $order): void
    {
        abort_if($order->canteen()->where('seller_id', $seller->id)->doesntExist(), 403, 'Pesanan bukan milik kantin Anda.');
    }
}
