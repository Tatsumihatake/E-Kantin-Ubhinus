<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\CanteenResource;
use App\Models\Canteen;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CanteenController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $canteens = Canteen::query()
            ->withCount('products')
            ->orderBy('name')
            ->paginate(20);

        return CanteenResource::collection($canteens);
    }

    public function show(Canteen $canteen): CanteenResource
    {
        $canteen->load(['products.category', 'products.addons']);

        return new CanteenResource($canteen);
    }
}
