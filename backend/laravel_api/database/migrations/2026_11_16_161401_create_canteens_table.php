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
        Schema::create('canteens', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('seller_id')->constrained('users')->restrictOnDelete();
            $table->string('name', 150);
            $table->text('description')->nullable();
            $table->text('image_url')->nullable();
            $table->jsonb('opening_hours')->default('{}');
            $table->boolean('is_open')->default(false);
            $table->timestampsTz();

            $table->index('seller_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('canteens');
    }
};
