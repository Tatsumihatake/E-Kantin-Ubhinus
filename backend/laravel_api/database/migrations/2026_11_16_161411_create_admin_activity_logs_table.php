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
        Schema::create('admin_activity_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('admin_id')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('seller_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('action', [
                'CREATE_ACCOUNT', 'UPDATE_ACCOUNT', 'ACTIVATE_ACCOUNT', 'DEACTIVATE_ACCOUNT',
            ]);
            $table->text('description')->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->index('admin_id');
            $table->index('seller_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('admin_activity_logs');
    }
};
