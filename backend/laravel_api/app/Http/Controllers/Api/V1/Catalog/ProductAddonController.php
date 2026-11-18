<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\AddonResource;
use App\Models\Product;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProductAddonController extends Controller
{
    public function index(Product $product): AnonymousResourceCollection
    {
        return AddonResource::collection(
            $product->addons()->where('is_available', true)->orderBy('name')->get()
        );
    }
}
