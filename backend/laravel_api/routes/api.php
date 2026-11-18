<?php

use App\Http\Controllers\Api\V1\Admin\SellerController as AdminSellerController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\Catalog\CanteenController;
use App\Http\Controllers\Api\V1\Catalog\CategoryController;
use App\Http\Controllers\Api\V1\Catalog\ProductAddonController;
use App\Http\Controllers\Api\V1\Catalog\ProductController;
use App\Http\Controllers\Api\V1\Customer\FavoriteController;
use App\Http\Controllers\Api\V1\Customer\OrderController;
use App\Http\Controllers\Api\V1\Customer\PaymentController;
use App\Http\Controllers\Api\V1\Seller\AddonController as SellerAddonController;
use App\Http\Controllers\Api\V1\Seller\CanteenController as SellerCanteenController;
use App\Http\Controllers\Api\V1\Seller\OrderController as SellerOrderController;
use App\Http\Controllers\Api\V1\Seller\ProductController as SellerProductController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::prefix('v1')->group(function (): void {
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/register', [AuthController::class, 'register']);

    Route::get('/canteens', [CanteenController::class, 'index']);
    Route::get('/canteens/{canteen}', [CanteenController::class, 'show']);
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{product}', [ProductController::class, 'show']);
    Route::get('/products/{product}/addons', [ProductAddonController::class, 'index']);

    Route::get('/media/{path}', function (string $path) {
        abort_unless(Storage::disk('public')->exists($path), 404);

        return response()->file(Storage::disk('public')->path($path));
    })->where('path', '.*');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::patch('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
    });

    Route::middleware(['auth:sanctum', 'role:CUSTOMER'])->group(function (): void {
        Route::get('/favorites', [FavoriteController::class, 'index']);
        Route::post('/favorites', [FavoriteController::class, 'store']);
        Route::delete('/favorites/{product}', [FavoriteController::class, 'destroy']);

        Route::post('/orders/preview', [OrderController::class, 'preview']);
        Route::post('/orders', [OrderController::class, 'store']);
        Route::get('/orders', [OrderController::class, 'index']);
        Route::post('/orders/{order}/payments', [PaymentController::class, 'store']);
        Route::get('/payments/{payment}', [PaymentController::class, 'show']);
        Route::post('/payments/{payment}/simulate-result', [PaymentController::class, 'simulate']);
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/orders/{order}', [OrderController::class, 'show']);
        Route::get('/orders/{order}/status-history', [OrderController::class, 'statusHistory']);
    });

    Route::prefix('seller')->middleware(['auth:sanctum', 'role:SELLER'])->group(function (): void {
        Route::get('/canteen', [SellerCanteenController::class, 'show']);
        Route::patch('/canteen', [SellerCanteenController::class, 'update']);

        Route::get('/products', [SellerProductController::class, 'index']);
        Route::post('/products', [SellerProductController::class, 'store']);
        Route::get('/products/{product}', [SellerProductController::class, 'show']);
        Route::patch('/products/{product}', [SellerProductController::class, 'update']);
        Route::delete('/products/{product}', [SellerProductController::class, 'destroy']);
        Route::post('/products/{product}/addons', [SellerAddonController::class, 'store']);
        Route::patch('/addons/{addon}', [SellerAddonController::class, 'update']);
        Route::delete('/addons/{addon}', [SellerAddonController::class, 'destroy']);

        Route::get('/orders', [SellerOrderController::class, 'index']);
        Route::get('/order-history', [SellerOrderController::class, 'history']);
        Route::post('/orders/{order}/accept', [SellerOrderController::class, 'accept']);
        Route::post('/orders/{order}/reject', [SellerOrderController::class, 'reject']);
        Route::patch('/orders/{order}/status', [SellerOrderController::class, 'updateStatus']);
    });

    Route::prefix('admin')->middleware(['auth:sanctum', 'role:ADMIN'])->group(function (): void {
        Route::get('/sellers', [AdminSellerController::class, 'index']);
        Route::post('/sellers', [AdminSellerController::class, 'store']);
        Route::get('/sellers/{seller}', [AdminSellerController::class, 'show']);
        Route::patch('/sellers/{seller}', [AdminSellerController::class, 'update']);
        Route::patch('/sellers/{seller}/activation', [AdminSellerController::class, 'activation']);
    });
});
