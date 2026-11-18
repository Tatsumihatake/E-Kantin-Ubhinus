<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('customer_id')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('canteen_id')->constrained('canteens')->restrictOnDelete();
            $table->enum('status', [
                'WAITING_PAYMENT', 'PAID', 'CONFIRMED', 'PREPARING',
                'READY', 'COMPLETED', 'REJECTED', 'CANCELLED',
            ])->default('WAITING_PAYMENT');
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('total', 12, 2)->default(0);
            $table->text('request')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestampsTz();

            $table->index('customer_id');
            $table->index('canteen_id');
            $table->index('status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
