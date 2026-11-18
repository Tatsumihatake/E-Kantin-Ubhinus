<?php

namespace App\Http\Controllers\Api\V1\Seller;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Seller\UpdateCanteenRequest;
use App\Http\Resources\CanteenResource;
use App\Models\Canteen;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CanteenController extends Controller
{
    public function show(Request $request): CanteenResource
    {
        $canteen = $this->canteen($request->user());
        $canteen->load('products.category');

        return new CanteenResource($canteen);
    }

    public function update(UpdateCanteenRequest $request): CanteenResource
    {
        $canteen = $this->canteen($request->user());
        $data = $request->safe()->except('image');

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('canteens', 'public');
            $data['image_url'] = Storage::url($path);
        }

        $canteen->update($data);

        return new CanteenResource($canteen->load('products.category'));
    }

    private function canteen(User $seller): Canteen
    {
        $canteen = $seller->canteens()->first();

        abort_if($canteen === null, 403, 'Akun Seller belum terhubung dengan kantin.');

        return $canteen;
    }
}
