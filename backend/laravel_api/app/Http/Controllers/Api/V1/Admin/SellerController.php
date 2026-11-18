<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\AdminAction;
use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\ActivateSellerRequest;
use App\Http\Requests\Api\V1\Admin\StoreSellerRequest;
use App\Http\Requests\Api\V1\Admin\UpdateSellerRequest;
use App\Http\Resources\SellerResource;
use App\Models\AdminActivityLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class SellerController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:active,inactive'],
        ]);

        $sellers = User::query()
            ->where('role', Role::Seller)
            ->with('canteens')
            ->when($validated['q'] ?? null, function ($query, string $q): void {
                $query->where(function ($query) use ($q): void {
                    $query->whereLike('name', "%{$q}%")
                        ->orWhereLike('email', "%{$q}%")
                        ->orWhereHas('canteens', fn ($canteen) => $canteen->whereLike('name', "%{$q}%"));
                });
            })
            ->when(
                $validated['status'] ?? null,
                fn ($query, string $status) => $query->where('is_active', $status === 'active')
            )
            ->latest('created_at')
            ->paginate(20);

        return SellerResource::collection($sellers);
    }

    public function store(StoreSellerRequest $request): JsonResponse
    {
        $seller = DB::transaction(function () use ($request): User {
            $seller = User::query()->create([
                'name' => $request->validated('name'),
                'email' => $request->validated('email'),
                'password' => $request->validated('password'),
                'phone' => $request->validated('phone'),
                'role' => Role::Seller,
                'is_active' => true,
            ]);

            $seller->canteens()->create([
                'name' => $request->validated('canteen_name'),
                'description' => $request->validated('canteen_description'),
                'opening_hours' => $request->validated('opening_hours') ?? [],
                'is_open' => false,
            ]);

            $this->log($request->user(), $seller, AdminAction::CreateAccount, "Akun Seller {$seller->name} dibuat.");

            return $seller;
        });

        return (new SellerResource($seller->load('canteens')))->response()->setStatusCode(201);
    }

    public function show(User $seller): SellerResource
    {
        $this->ensureSeller($seller);

        return new SellerResource($seller->load('canteens'));
    }

    public function update(UpdateSellerRequest $request, User $seller): SellerResource
    {
        $this->ensureSeller($seller);

        DB::transaction(function () use ($request, $seller): void {
            $data = $request->safe()->only(['name', 'email', 'phone']);

            if ($request->filled('password')) {
                $data['password'] = $request->validated('password');
            }

            $seller->update($data);

            $canteenData = $request->safe()->only([
                'canteen_name', 'canteen_description', 'opening_hours', 'is_open',
            ]);

            $mapped = array_filter([
                'name' => $canteenData['canteen_name'] ?? null,
                'description' => $canteenData['canteen_description'] ?? null,
                'opening_hours' => $canteenData['opening_hours'] ?? null,
                'is_open' => $canteenData['is_open'] ?? null,
            ], fn ($value): bool => $value !== null);

            if ($mapped !== []) {
                $seller->canteens()->first()?->update($mapped);
            }

            $this->log($request->user(), $seller, AdminAction::UpdateAccount, "Akun Seller {$seller->name} diubah.");
        });

        return new SellerResource($seller->load('canteens'));
    }

    public function activation(ActivateSellerRequest $request, User $seller): SellerResource
    {
        $this->ensureSeller($seller);

        $isActive = $request->validated('is_active');
        $seller->update(['is_active' => $isActive]);

        if (! $isActive) {
            $seller->tokens()->delete();
        }

        $this->log(
            $request->user(),
            $seller,
            $isActive ? AdminAction::ActivateAccount : AdminAction::DeactivateAccount,
            "Akun Seller {$seller->name} ".($isActive ? 'diaktifkan.' : 'dinonaktifkan.')
        );

        return new SellerResource($seller->load('canteens'));
    }

    private function ensureSeller(User $seller): void
    {
        abort_if($seller->role !== Role::Seller, 404, 'Seller tidak ditemukan.');
    }

    private function log(User $admin, User $seller, AdminAction $action, string $description): void
    {
        AdminActivityLog::query()->create([
            'admin_id' => $admin->id,
            'seller_id' => $seller->id,
            'action' => $action,
            'description' => $description,
        ]);
    }
}
