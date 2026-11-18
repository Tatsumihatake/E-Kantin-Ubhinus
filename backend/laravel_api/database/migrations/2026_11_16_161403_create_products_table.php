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
        Schema::create('products', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('canteen_id')->constrained('canteens')->restrictOnDelete();
            $table->foreignUuid('category_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('name', 150);
            $table->text('description')->nullable();
            $table->text('image_url')->nullable();
            $table->decimal('price', 12, 2);
            $table->boolean('is_available')->default(true);
            $table->timestampsTz();

            $table->index('canteen_id');
            $table->index('category_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
