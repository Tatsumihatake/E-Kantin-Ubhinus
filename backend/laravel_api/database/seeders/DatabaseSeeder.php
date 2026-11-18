<?php

namespace Database\Seeders;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\Role;
use App\Enums\SelectionRule;
use App\Models\Addon;
use App\Models\Canteen;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderItemAddon;
use App\Models\OrderStatusHistory;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        User::query()->create([
            'name' => 'Admin Kampus',
            'email' => 'admin@ekantin.test',
            'password' => 'password',
            'role' => Role::Admin,
        ]);

        $sellerSari = User::query()->create([
            'name' => 'Ibu Siti Sari',
            'email' => 'seller1@ekantin.test',
            'password' => 'password',
            'role' => Role::Seller,
            'phone' => '081234567001',
        ]);

        $sellerBambang = User::query()->create([
            'name' => 'Mas Bambang',
            'email' => 'seller2@ekantin.test',
            'password' => 'password',
            'role' => Role::Seller,
            'phone' => '081234567002',
        ]);

        $customer = User::query()->create([
            'name' => 'Budi Prasetyo',
            'email' => 'customer@ekantin.test',
            'password' => 'password',
            'role' => Role::Customer,
            'phone' => '081234567003',
        ]);

        $categories = collect(['Nasi', 'Mie', 'Snack', 'Minuman'])
            ->mapWithKeys(fn (string $name): array => [
                $name => Category::query()->create(['name' => $name]),
            ]);

        $sariCanteen = Canteen::query()->create([
            'seller_id' => $sellerSari->id,
            'name' => 'Kantin Bu Sari',
            'description' => 'Masakan rumahan dan paket hemat mahasiswa.',
            'opening_hours' => ['monday_friday' => '07:00-16:00'],
            'is_open' => true,
        ]);

        $bambangCanteen = Canteen::query()->create([
            'seller_id' => $sellerBambang->id,
            'name' => 'Ayam Geprek Mas Bambang',
            'description' => 'Ayam geprek pedas dengan sambal korek.',
            'opening_hours' => ['monday_saturday' => '09:00-20:00'],
            'is_open' => true,
        ]);

        $sariProducts = $this->createProducts($sariCanteen, $categories->all(), [
            ['Nasi Rendang', 'Nasi', 20000, 'Rendang sapi dengan nasi dan sayur.'],
            ['Nasi Ayam Kecap', 'Nasi', 18000, 'Ayam kecap manis dengan nasi hangat.'],
            ['Mie Goreng Spesial', 'Mie', 14000, 'Mie goreng dengan telur dan sayuran.'],
            ['Mie Kuah Bakso', 'Mie', 15000, 'Mie kuah dengan bakso sapi.'],
            ['Pisang Goreng', 'Snack', 7000, 'Pisang goreng renyah, isi 4 potong.'],
            ['Es Teh Manis', 'Minuman', 5000, 'Teh manis dingin.'],
        ]);

        $bambangProducts = $this->createProducts($bambangCanteen, $categories->all(), [
            ['Ayam Geprek Sambal Korek', 'Nasi', 18000, 'Ayam crispy dengan sambal korek dan nasi hangat.'],
            ['Nasi Ayam Teriyaki', 'Nasi', 20000, 'Ayam teriyaki dengan nasi dan sayur.'],
            ['Mie Ayam Bakso', 'Mie', 16000, 'Mie ayam dengan bakso dan pangsit.'],
            ['Tahu Crispy', 'Snack', 8000, 'Tahu goreng crispy dengan saus.'],
            ['Kentang Goreng', 'Snack', 10000, 'Kentang goreng dengan bumbu tabur.'],
            ['Es Jeruk', 'Minuman', 6000, 'Jeruk peras segar dengan es.'],
        ]);

        $geprek = $bambangProducts['Ayam Geprek Sambal Korek'];

        $telur = Addon::query()->create([
            'product_id' => $geprek->id,
            'name' => 'Telur Ceplok',
            'price' => 3000,
            'selection_rule' => SelectionRule::Optional,
            'is_available' => true,
        ]);

        $level = Addon::query()->create([
            'product_id' => $geprek->id,
            'name' => 'Level Pedas',
            'price' => 0,
            'selection_rule' => SelectionRule::Required,
            'is_available' => true,
        ]);

        $bakso = Addon::query()->create([
            'product_id' => $bambangProducts['Mie Ayam Bakso']->id,
            'name' => 'Bakso Tambahan',
            'price' => 5000,
            'selection_rule' => SelectionRule::Optional,
            'is_available' => true,
        ]);

        $this->seedOrders(
            $customer,
            $sellerSari,
            $sellerBambang,
            $sariCanteen,
            $bambangCanteen,
            $sariProducts,
            $bambangProducts,
            $telur,
            $level,
            $bakso,
        );
    }

    /**
     * @param  array<string, Category>  $categories
     * @param  array<int, array{0: string, 1: string, 2: int, 3: string}>  $definitions
     * @return array<string, Product>
     */
    private function createProducts(Canteen $canteen, array $categories, array $definitions): array
    {
        $products = [];

        foreach ($definitions as [$name, $category, $price, $description]) {
            $products[$name] = Product::query()->create([
                'canteen_id' => $canteen->id,
                'category_id' => $categories[$category]->id,
                'name' => $name,
                'description' => $description,
                'price' => $price,
                'is_available' => true,
            ]);
        }

        return $products;
    }

    /**
     * @param  array<string, Product>  $sariProducts
     * @param  array<string, Product>  $bambangProducts
     */
    private function seedOrders(
        User $customer,
        User $sellerSari,
        User $sellerBambang,
        Canteen $sariCanteen,
        Canteen $bambangCanteen,
        array $sariProducts,
        array $bambangProducts,
        Addon $telur,
        Addon $level,
        Addon $bakso,
    ): void {
        $this->createOrder(
            $customer,
            $sariCanteen,
            [
                ['product' => $sariProducts['Nasi Rendang'], 'quantity' => 1, 'addons' => []],
                ['product' => $sariProducts['Es Teh Manis'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::Completed,
            PaymentStatus::Success,
            now()->subDays(6)->setTime(12, 15),
            $sellerSari,
        );

        $this->createOrder(
            $customer,
            $bambangCanteen,
            [
                ['product' => $bambangProducts['Ayam Geprek Sambal Korek'], 'quantity' => 2, 'addons' => [$level, $telur]],
                ['product' => $bambangProducts['Es Jeruk'], 'quantity' => 2, 'addons' => []],
            ],
            OrderStatus::Completed,
            PaymentStatus::Success,
            now()->subDays(5)->setTime(19, 5),
            $sellerBambang,
        );

        $this->createOrder(
            $customer,
            $bambangCanteen,
            [
                ['product' => $bambangProducts['Nasi Ayam Teriyaki'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::Rejected,
            PaymentStatus::Success,
            now()->subDays(4)->setTime(11, 40),
            $sellerBambang,
            'Stok ayam habis, silakan pesan menu lain.',
        );

        $this->createOrder(
            $customer,
            $sariCanteen,
            [
                ['product' => $sariProducts['Mie Kuah Bakso'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::Cancelled,
            PaymentStatus::Cancelled,
            now()->subDays(3)->setTime(13, 20),
            $customer,
        );

        $this->createOrder(
            $customer,
            $sariCanteen,
            [
                ['product' => $sariProducts['Mie Goreng Spesial'], 'quantity' => 1, 'addons' => []],
                ['product' => $sariProducts['Pisang Goreng'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::Preparing,
            PaymentStatus::Success,
            now()->subDay()->setTime(10, 30),
            $sellerSari,
        );

        $this->createOrder(
            $customer,
            $bambangCanteen,
            [
                ['product' => $bambangProducts['Mie Ayam Bakso'], 'quantity' => 1, 'addons' => [$bakso]],
            ],
            OrderStatus::Confirmed,
            PaymentStatus::Success,
            now()->subDay()->setTime(18, 45),
            $sellerBambang,
        );

        $this->createOrder(
            $customer,
            $sariCanteen,
            [
                ['product' => $sariProducts['Nasi Ayam Kecap'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::Paid,
            PaymentStatus::Success,
            now()->subHours(2),
            $customer,
        );

        $this->createOrder(
            $customer,
            $bambangCanteen,
            [
                ['product' => $bambangProducts['Kentang Goreng'], 'quantity' => 1, 'addons' => []],
            ],
            OrderStatus::WaitingPayment,
            PaymentStatus::Pending,
            now()->subMinutes(30),
            $customer,
        );
    }

    /**
     * @param  array<int, array{product: Product, quantity: int, addons: array<int, Addon>}>  $lines
     */
    private function createOrder(
        User $customer,
        Canteen $canteen,
        array $lines,
        OrderStatus $status,
        PaymentStatus $paymentStatus,
        Carbon $placedAt,
        ?User $actor = null,
        ?string $rejectionReason = null,
    ): Order {
        $subtotal = 0.0;

        foreach ($lines as $line) {
            $addonTotal = array_sum(array_map(fn (Addon $addon): float => (float) $addon->price, $line['addons']));
            $subtotal += ((float) $line['product']->price + $addonTotal) * $line['quantity'];
        }

        $order = Order::query()->create([
            'customer_id' => $customer->id,
            'canteen_id' => $canteen->id,
            'status' => $status,
            'subtotal' => $subtotal,
            'total' => $subtotal,
            'rejection_reason' => $rejectionReason,
        ]);

        $this->stamp($order, $placedAt, true);

        foreach ($lines as $line) {
            $addonTotal = array_sum(array_map(fn (Addon $addon): float => (float) $addon->price, $line['addons']));
            $lineSubtotal = ((float) $line['product']->price + $addonTotal) * $line['quantity'];

            $item = OrderItem::query()->create([
                'order_id' => $order->id,
                'product_id' => $line['product']->id,
                'product_name_snapshot' => $line['product']->name,
                'unit_price' => $line['product']->price,
                'quantity' => $line['quantity'],
                'subtotal' => $lineSubtotal,
            ]);

            $this->stamp($item, $placedAt);

            foreach ($line['addons'] as $addon) {
                $itemAddon = $item->addons()->create([
                    'addon_id' => $addon->id,
                    'addon_name_snapshot' => $addon->name,
                    'addon_price' => $addon->price,
                    'quantity' => 1,
                ]);

                $this->stamp($itemAddon, $placedAt);
            }
        }

        $this->createStatusHistory($order, $status, $placedAt, $actor);

        Payment::query()->create([
            'order_id' => $order->id,
            'method' => 'QRIS',
            'amount' => $subtotal,
            'status' => $paymentStatus,
            'reference' => 'SEED-'.strtoupper($order->id),
            'paid_at' => $paymentStatus === PaymentStatus::Success ? $placedAt->copy()->addMinutes(3) : null,
        ]);

        return $order;
    }

    private function createStatusHistory(Order $order, OrderStatus $status, Carbon $placedAt, ?User $actor): void
    {
        $chain = match ($status) {
            OrderStatus::WaitingPayment => [OrderStatus::WaitingPayment],
            OrderStatus::Paid => [OrderStatus::WaitingPayment, OrderStatus::Paid],
            OrderStatus::Confirmed => [OrderStatus::WaitingPayment, OrderStatus::Paid, OrderStatus::Confirmed],
            OrderStatus::Preparing => [OrderStatus::WaitingPayment, OrderStatus::Paid, OrderStatus::Confirmed, OrderStatus::Preparing],
            OrderStatus::Ready => [OrderStatus::WaitingPayment, OrderStatus::Paid, OrderStatus::Confirmed, OrderStatus::Preparing, OrderStatus::Ready],
            OrderStatus::Completed => [OrderStatus::WaitingPayment, OrderStatus::Paid, OrderStatus::Confirmed, OrderStatus::Preparing, OrderStatus::Ready, OrderStatus::Completed],
            OrderStatus::Rejected => [OrderStatus::WaitingPayment, OrderStatus::Paid, OrderStatus::Rejected],
            OrderStatus::Cancelled => [OrderStatus::WaitingPayment, OrderStatus::Cancelled],
        };

        $previous = null;
        $at = $placedAt->copy();

        foreach ($chain as $index => $newStatus) {
            if ($index > 0) {
                $at = $at->copy()->addMinutes(5);
            }

            $history = OrderStatusHistory::query()->create([
                'order_id' => $order->id,
                'old_status' => $previous,
                'new_status' => $newStatus,
                'changed_by' => $actor?->id,
                'note' => $index === 0 ? 'Order dibuat.' : null,
            ]);

            $this->stamp($history, $at);

            $previous = $newStatus;
        }
    }

    private function stamp(Order|OrderItem|OrderItemAddon|OrderStatusHistory $model, Carbon $at, bool $withUpdatedAt = false): void
    {
        $model->timestamps = false;

        $attributes = ['created_at' => $at];

        if ($withUpdatedAt) {
            $attributes['updated_at'] = $at;
        }

        $model->forceFill($attributes)->save();
        $model->timestamps = true;
    }
}
