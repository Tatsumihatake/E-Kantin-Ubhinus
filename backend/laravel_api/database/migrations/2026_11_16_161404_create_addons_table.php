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
        Schema::create('addons', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('name', 100);
            $table->decimal('price', 12, 2)->default(0);
            $table->enum('selection_rule', ['OPTIONAL', 'REQUIRED'])->default('OPTIONAL');
            $table->boolean('is_available')->default(true);
            $table->timestampsTz();

            $table->index('product_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('addons');
    }
};
