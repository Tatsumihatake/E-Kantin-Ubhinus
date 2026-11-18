<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'canteen_id' => ['nullable', 'uuid', Rule::exists('canteens', 'id')],
            'category_id' => ['nullable', 'uuid', Rule::exists('categories', 'id')],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $products = Product::query()
            ->with(['canteen', 'category'])
            ->when($validated['q'] ?? null, function ($query, string $q): void {
                $query->where(function ($query) use ($q): void {
                    $query->whereLike('name', "%{$q}%")
                        ->orWhereHas('canteen', fn ($canteen) => $canteen->whereLike('name', "%{$q}%"));
                });
            })
            ->when($validated['canteen_id'] ?? null, fn ($query, string $id) => $query->where('canteen_id', $id))
            ->when($validated['category_id'] ?? null, fn ($query, string $id) => $query->where('category_id', $id))
            ->orderByDesc('is_available')
            ->orderBy('name')
            ->paginate($validated['per_page'] ?? 20);

        return ProductResource::collection($products);
    }

    public function show(Product $product): ProductResource
    {
        $product->load(['canteen', 'category', 'addons' => fn ($query) => $query->orderBy('name')]);

        return new ProductResource($product);
    }
}
