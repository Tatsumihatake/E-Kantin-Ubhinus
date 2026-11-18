<?php

namespace App\Http\Controllers\Api\V1\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\FavoriteResource;
use App\Models\Favorite;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class FavoriteController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $favorites = Favorite::query()
            ->where('customer_id', $request->user()->id)
            ->with(['product.canteen', 'product.category'])
            ->latest('created_at')
            ->get();

        return FavoriteResource::collection($favorites);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_id' => ['required', 'uuid', Rule::exists('products', 'id')],
        ]);

        $favorite = Favorite::query()->firstOrCreate([
            'customer_id' => $request->user()->id,
            'product_id' => $validated['product_id'],
        ]);

        $favorite->load(['product.canteen', 'product.category']);

        return (new FavoriteResource($favorite))
            ->response()
            ->setStatusCode($favorite->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        Favorite::query()
            ->where('customer_id', $request->user()->id)
            ->where('product_id', $product->id)
            ->delete();

        return response()->json(null, 204);
    }
}
