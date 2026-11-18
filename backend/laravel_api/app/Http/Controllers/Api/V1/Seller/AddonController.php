<?php

namespace App\Http\Controllers\Api\V1\Seller;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Seller\StoreAddonRequest;
use App\Http\Requests\Api\V1\Seller\UpdateAddonRequest;
use App\Http\Resources\AddonResource;
use App\Models\Addon;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddonController extends Controller
{
    public function store(StoreAddonRequest $request, Product $product): JsonResponse
    {
        $this->authorizeProduct($request->user(), $product);

        $addon = $product->addons()->create($request->validated());

        return (new AddonResource($addon))->response()->setStatusCode(201);
    }

    public function update(UpdateAddonRequest $request, Addon $addon): AddonResource
    {
        $this->authorizeAddon($request->user(), $addon);

        $addon->update($request->validated());

        return new AddonResource($addon);
    }

    public function destroy(Request $request, Addon $addon): JsonResponse
    {
        $this->authorizeAddon($request->user(), $addon);

        $addon->delete();

        return response()->json(null, 204);
    }

    private function authorizeProduct(User $seller, Product $product): void
    {
        abort_if($product->canteen()->where('seller_id', $seller->id)->doesntExist(), 403, 'Produk bukan milik kantin Anda.');
    }

    private function authorizeAddon(User $seller, Addon $addon): void
    {
        abort_if(
            $addon->product()->whereHas('canteen', fn ($query) => $query->where('seller_id', $seller->id))->doesntExist(),
            403,
            'Add-on bukan milik kantin Anda.'
        );
    }
}
