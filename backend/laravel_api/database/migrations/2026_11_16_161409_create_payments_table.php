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
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('order_id')->constrained('orders')->restrictOnDelete();
            $table->string('method', 30);
            $table->decimal('amount', 12, 2);
            $table->enum('status', ['PENDING', 'SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'])
                ->default('PENDING');
            $table->string('reference', 150)->nullable()->unique();
            $table->timestampTz('paid_at')->nullable();
            $table->timestampsTz();

            $table->index('order_id');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
