<?php

namespace App\Http\Controllers\Api\V1\Customer;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Customer\PreviewOrderRequest;
use App\Http\Requests\Api\V1\Customer\StoreOrderRequest;
use App\Http\Resources\AddonResource;
use App\Http\Resources\OrderResource;
use App\Http\Resources\OrderStatusHistoryResource;
use App\Http\Resources\ProductResource;
use App\Models\Order;
use App\Services\OrderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Gate;

class OrderController extends Controller
{
    public function __construct(private readonly OrderService $orderService) {}

    public function preview(PreviewOrderRequest $request): JsonResponse
    {
        $selection = $this->orderService->preview($request->validated());

        return response()->json([
            'data' => [
                'product' => (new ProductResource($selection['product']))->resolve(),
                'quantity' => $selection['quantity'],
                'addons' => AddonResource::collection($selection['addons'])->resolve(),
                'request' => $selection['request'],
                'unit_price' => $selection['unit_price'],
                'addons_total' => $selection['addons_total'],
                'unit_total' => $selection['unit_total'],
                'total' => $selection['total'],
            ],
        ]);
    }

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $customer = $request->user();
        $key = $request->validated('idempotency_key');
        $cacheKey = $key ? "orders:idempotency:{$customer->id}:{$key}" : null;

        if ($cacheKey && $orderId = Cache::get($cacheKey)) {
            $order = Order::query()->with(['items.addons', 'canteen', 'statusHistory'])->findOrFail($orderId);

            return (new OrderResource($order))->response()->setStatusCode(200);
        }

        $order = $this->orderService->create($customer, $request->validated());

        if ($cacheKey) {
            Cache::put($cacheKey, $order->id, now()->addMinutes(10));
        }

        return (new OrderResource($order))->response()->setStatusCode(201);
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'tab' => ['nullable', 'in:active,finished'],
        ]);

        $statuses = collect(OrderStatus::cases())
            ->filter(fn (OrderStatus $status): bool => match ($validated['tab'] ?? null) {
                'active' => $status->isActive(),
                'finished' => $status->isFinal(),
                default => true,
            })
            ->map(fn (OrderStatus $status): string => $status->value)
            ->all();

        $orders = Order::query()
            ->where('customer_id', $request->user()->id)
            ->whereIn('status', $statuses)
            ->with(['items.addons', 'canteen'])
            ->latest('created_at')
            ->paginate(20);

        return OrderResource::collection($orders);
    }

    public function show(Order $order): OrderResource
    {
        Gate::authorize('view', $order);

        $order->load([
            'items.addons',
            'canteen',
            'statusHistory.changedBy',
        ]);

        return new OrderResource($order);
    }

    public function statusHistory(Order $order): AnonymousResourceCollection
    {
        Gate::authorize('view', $order);

        $history = $order->statusHistory()->with('changedBy')->oldest('created_at')->get();

        return OrderStatusHistoryResource::collection($history);
    }
}
