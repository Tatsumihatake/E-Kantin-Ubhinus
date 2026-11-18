<?php

namespace App\Http\Controllers\Api\V1\Seller;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Seller\StoreProductRequest;
use App\Http\Requests\Api\V1\Seller\UpdateProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Canteen;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $canteen = $this->canteen($request->user());

        $products = $canteen->products()
            ->with(['category', 'addons'])
            ->orderBy('name')
            ->paginate(30);

        return ProductResource::collection($products);
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        $canteen = $this->canteen($request->user());
        $data = $request->safe()->except('image');
        $data['canteen_id'] = $canteen->id;
        $data['is_available'] ??= true;

        if ($request->hasFile('image')) {
            $data['image_url'] = Storage::url($request->file('image')->store('products', 'public'));
        }

        $product = $canteen->products()->create($data);

        return (new ProductResource($product->load(['category', 'addons'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Product $product): ProductResource
    {
        $this->authorizeProduct($request->user(), $product);

        return new ProductResource($product->load(['category', 'addons']));
    }

    public function update(UpdateProductRequest $request, Product $product): ProductResource
    {
        $this->authorizeProduct($request->user(), $product);

        $data = $request->safe()->except('image');

        if ($request->hasFile('image')) {
            $data['image_url'] = Storage::url($request->file('image')->store('products', 'public'));
        }

        $product->update($data);

        return new ProductResource($product->load(['category', 'addons']));
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        $this->authorizeProduct($request->user(), $product);

        $product->update(['is_available' => false]);

        return response()->json(null, 204);
    }

    private function canteen(User $seller): Canteen
    {
        $canteen = $seller->canteens()->first();

        abort_if($canteen === null, 403, 'Akun Seller belum terhubung dengan kantin.');

        return $canteen;
    }

    private function authorizeProduct(User $seller, Product $product): void
    {
        abort_if($product->canteen()->where('seller_id', $seller->id)->doesntExist(), 403, 'Produk bukan milik kantin Anda.');
    }
}
